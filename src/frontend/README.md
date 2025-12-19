Frontend (Vite + React) quick start

1. Install dependencies:

```bash
cd src/frontend
npm install
```

2. Start dev server:

```bash
npm run dev
```

The app will run at `http://localhost:5173` by default and calls the backend at `http://localhost:8000`.

Set `FRONTEND_ORIGINS` in backend `.env` to `http://localhost:5173` if needed.
