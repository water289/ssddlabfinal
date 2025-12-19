from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(150), unique=True, index=True, nullable=False)
    hashed_password = Column(String(256), nullable=False)
    role = Column(String(50), default="voter")
    created_at = Column(DateTime, default=datetime.utcnow)
    votes = relationship("Vote", back_populates="voter")

class Election(Base):
    __tablename__ = "elections"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    votes = relationship("Vote", back_populates="election")

class Vote(Base):
    __tablename__ = "votes"
    id = Column(Integer, primary_key=True, index=True)
    election_id = Column(Integer, ForeignKey("elections.id"), nullable=False)
    voter_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    choice = Column(String(1024), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    election = relationship("Election", back_populates="votes")
    voter = relationship("User", back_populates="votes")
    __table_args__ = (UniqueConstraint('election_id', 'voter_id', name='_election_voter_uc'),)
