import hashlib
import json
import logging
import os
import time
from collections import Counter
from datetime import datetime
from typing import Dict, List

from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel, Field
from prometheus_client import Counter as PromCounter
from prometheus_client import Histogram, make_asgi_app
from sqlalchemy import text
from sqlalchemy.orm import Session
from dotenv import load_dotenv

from . import auth, database, models, crypto

load_dotenv()
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="Secure Voting Backend")

FRONTEND_ORIGINS = [origin for origin in os.getenv("FRONTEND_ORIGINS", "http://localhost:5173").split(",") if origin]
app.add_middleware(
    CORSMiddleware,
    allow_origins=FRONTEND_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger("secure_voting")

# Prometheus metrics
REQUEST_COUNT = PromCounter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "Request latency in seconds",
    ["method", "path"],
)
VOTES_CAST = PromCounter("votes_cast_total", "Total votes cast")
REGISTRATIONS = PromCounter("registrations_total", "Total user registrations")

RATE_LIMIT_ENABLED = os.getenv("RATE_LIMIT_ENABLED", "true").lower() == "true"
RATE_LIMIT_PER_MINUTE = int(os.getenv("RATE_LIMIT_PER_MINUTE", "60"))
_RATE_BUCKET: Dict[str, List[float]] = {}


def _log_event(event: str, **kwargs) -> None:
    logger.info(json.dumps({"event": event, **kwargs}))


@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    if RATE_LIMIT_ENABLED and RATE_LIMIT_PER_MINUTE > 0:
        now = time.time()
        window_start = now - 60
        client_id = request.client.host if request.client else "unknown"
        history = [t for t in _RATE_BUCKET.get(client_id, []) if t >= window_start]
        if len(history) >= RATE_LIMIT_PER_MINUTE:
            return JSONResponse(status_code=429, content={"detail": "Rate limit exceeded"})
        history.append(now)
        _RATE_BUCKET[client_id] = history
    response = await call_next(request)
    return response


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    duration = time.perf_counter() - start
    method = request.method
    path = request.url.path
    status_code = response.status_code
    REQUEST_LATENCY.labels(method=method, path=path).observe(duration)
    REQUEST_COUNT.labels(method=method, path=path, status=status_code).inc()
    return response


app.mount("/metrics", make_asgi_app())


def compute_digest(counts: Dict[str, int]) -> str:
    digest = hashlib.sha256()
    for choice in sorted(counts.keys()):
        digest.update(f"{choice}:{counts[choice]}".encode())
    return digest.hexdigest()
@app.on_event("startup")
def ensure_admin_user() -> None:
    admin_username = os.getenv("ADMIN_USERNAME", "admin")
    admin_password = os.getenv("ADMIN_PASSWORD", "Admin@123")
    if not admin_username or not admin_password:
        return
    db: Session = database.SessionLocal()
    try:
        existing = db.query(models.User).filter(models.User.username == admin_username).first()
        if existing:
            return
        admin = models.User(
            username=admin_username,
            hashed_password=auth.get_password_hash(admin_password),
            role="admin",
        )
        db.add(admin)
        db.commit()
        _log_event("admin_seeded", username=admin_username)
    finally:
        db.close()


class RegisterIn(BaseModel):
    username: str = Field(..., min_length=3, max_length=150)
    password: str = Field(..., min_length=8)


class ElectionIn(BaseModel):
    title: str = Field(..., min_length=3)


class VoteIn(BaseModel):
    election_id: int
    choice: str = Field(..., min_length=1)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class ElectionOut(BaseModel):
    id: int
    title: str
    is_active: bool


class ResultOut(BaseModel):
    election: str
    results: Dict[str, int]
    digest: str


class UserOut(BaseModel):
    username: str
    role: str


class VoteOut(BaseModel):
    election_id: int
    choice: str
    created_at: datetime

@app.post("/auth/register", response_model=UserOut)
def register(payload: RegisterIn, db: Session = Depends(database.get_db)):
    existing = db.query(models.User).filter(models.User.username == payload.username).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already registered")
    user = models.User(username=payload.username, hashed_password=auth.get_password_hash(payload.password))
    db.add(user)
    db.commit()
    db.refresh(user)
    REGISTRATIONS.inc()
    _log_event("user_registered", username=user.username)
    return {"username": user.username, "role": user.role}

@app.post("/auth/token", response_model=TokenResponse)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(database.get_db)):
    user = auth.authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incorrect username or password")
    access_token = auth.create_access_token(data={"sub": user.username, "role": user.role})
    _log_event("user_authenticated", username=user.username)
    return {"access_token": access_token}


@app.get("/users/me", response_model=UserOut)
def read_current_user(current_user: models.User = Depends(auth.get_current_user)):
    return {"username": current_user.username, "role": current_user.role}


@app.get("/users/me/votes", response_model=List[VoteOut])
def read_my_votes(current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    votes = (
        db.query(models.Vote)
        .filter(models.Vote.voter_id == current_user.id)
        .order_by(models.Vote.created_at.desc())
        .all()
    )
    # Decrypt choices for user view
    out: List[VoteOut] = []
    for v in votes:
        try:
            choice = crypto.decrypt_text(v.choice)
        except Exception:
            choice = "<unavailable>"
        out.append({"election_id": v.election_id, "choice": choice, "created_at": v.created_at})
    return out

@app.get("/elections", response_model=List[ElectionOut])
def list_elections(include_inactive: bool = False, db: Session = Depends(database.get_db)):
    query = db.query(models.Election)
    if not include_inactive:
        query = query.filter(models.Election.is_active == True)
    return query.order_by(models.Election.created_at.desc()).all()


@app.post("/elections", response_model=ElectionOut, dependencies=[Depends(auth.require_role("admin"))])
def create_election(payload: ElectionIn, db: Session = Depends(database.get_db)):
    election = models.Election(title=payload.title)
    db.add(election)
    db.commit()
    db.refresh(election)
    _log_event("election_created", election_id=election.id, title=election.title)
    return election


@app.post("/elections/{election_id}/close", dependencies=[Depends(auth.require_role("admin"))])
def close_election(election_id: int, db: Session = Depends(database.get_db)):
    election = db.query(models.Election).filter(models.Election.id == election_id).first()
    if not election:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Election not found")
    election.is_active = False
    db.commit()
    _log_event("election_closed", election_id=election.id)
    return {"id": election.id, "is_active": election.is_active}


@app.post("/vote", response_model=Dict[str, int])
def cast_vote(payload: VoteIn, current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    election = db.query(models.Election).filter(models.Election.id == payload.election_id, models.Election.is_active == True).first()
    if not election:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Election not found or not active")
    existing = (
        db.query(models.Vote)
        .filter(models.Vote.election_id == payload.election_id, models.Vote.voter_id == current_user.id)
        .first()
    )
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Voter has already voted in this election")
    try:
        encrypted_choice = crypto.encrypt_text(payload.choice)
    except Exception:
        raise HTTPException(status_code=500, detail="Encryption failure")
    vote = models.Vote(election_id=payload.election_id, voter_id=current_user.id, choice=encrypted_choice)
    db.add(vote)
    db.commit()
    db.refresh(vote)
    VOTES_CAST.inc()
    _log_event("vote_cast", election_id=payload.election_id, username=current_user.username)
    # decrypt all choices to compute counts
    encrypted_rows = db.query(models.Vote.choice).filter(models.Vote.election_id == payload.election_id).all()
    choices: List[str] = []
    for row in encrypted_rows:
        try:
            choices.append(crypto.decrypt_text(row[0]))
        except Exception:
            continue
    counts = dict(Counter(choices))
    return counts


@app.get(
    "/elections/{election_id}/results",
    response_model=ResultOut,
    dependencies=[Depends(auth.require_role("admin"))],
)
def get_results(election_id: int, db: Session = Depends(database.get_db)):
    election = db.query(models.Election).filter(models.Election.id == election_id).first()
    if not election:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Election not found")
    votes = db.query(models.Vote).filter(models.Vote.election_id == election_id).all()
    choices: List[str] = []
    for v in votes:
        try:
            choices.append(crypto.decrypt_text(v.choice))
        except Exception:
            continue
    counts = dict(Counter(choices))
    digest = compute_digest(counts)
    return {"election": election.title, "results": counts, "digest": digest}


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.get("/ready")
def ready(db: Session = Depends(database.get_db)) -> Dict[str, str]:
    try:
        db.execute(text("SELECT 1"))
    except Exception:
        raise HTTPException(status_code=503, detail="Database not ready")
    return {"status": "ready"}
