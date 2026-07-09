# TraceX — AI-Powered PCB AOI Manufacturing Intelligence Platform

TraceX is a production-grade industrial software application designed for SMT (Surface Mount Technology) assembly line monitoring and quality control. It leverages AI (Ollama Qwen3:8B) to generate actionable operator instructions and electrical failure analyses for detected board defects.

---

## Technical Stack & Architecture

### Backend
- **FastAPI**: Asynchronous REST framework.
- **SQLAlchemy 2.0 & PostgreSQL**: Relational database storage.
- **JWT & Passlib (Bcrypt)**: Secure authentication context.
- **Ollama REST API**: Integrates local LLM `qwen3:8b` for expert recommendations.
- **Docker Compose**: Orchestrates database, cache, and app containers.

### Frontend
- **Flutter (Material 3)**: Dark industrial design palette matching factory terminals.
- **Riverpod**: State management.
- **GoRouter**: Modular shell routing for bottom navigation.
- **Dio**: Robust networking client with security interceptors.
- **fl_chart**: Real-time line, yield, and defect density heatmaps.
- **PDF & OpenFile**: On-demand inspection report compiler and document opener.

---

## Project Structure

```
tracex/
├── backend/                 # FastAPI application
│   ├── app/
│   │   ├── api/             # API Endpoints (auth, boards, alerts, analytics, AI)
│   │   ├── auth/            # JWT validation and password hashing
│   │   ├── database/        # Session and engine builders
│   │   ├── models/          # SQLAlchemy Database Models
│   │   ├── schemas/         # Pydantic schemas (validation)
│   │   ├── services/        # AI (Ollama) & Notifications
│   │   └── main.py          # FastAPI application entrypoint
│   ├── seed.py              # Mock data database seeder
│   ├── requirements.txt     # Python dependencies
│   └── Dockerfile           # Backend container
├── frontend/                # Flutter frontend
│   ├── lib/
│   │   ├── core/            # Theme, routing, secure storage, API Client
│   │   ├── features/        # Home, Alerts, Boards, Analytics, Settings
│   │   ├── models/          # Dart models with JSON helpers
│   │   └── main.dart        # Flutter entrypoint
│   └── pubspec.yaml         # Dart dependencies
├── docker-compose.yml       # Docker environment orchestration
└── .env                     # Local environment settings
```

---

## Setup & Execution Instructions

### 1. Backend Service Launch (Docker)

Spin up PostgreSQL, Redis, and the FastAPI application instantly using Docker Compose:

```bash
# Clone the repository and navigate to root
cd C:\Users\samiya\.gemini\antigravity\scratch\tracex

# Launch containers
docker-compose up -d
```

### 2. Manual Local Setup (Without Docker)

If you prefer to run services natively on your system:

#### A. Setup Database
Ensure PostgreSQL is active and create a database named `tracex`.

#### B. Setup Python Environment
```bash
cd backend
python -m venv venv
venv\Scripts\activate   # Windows

# Install packages
pip install -r requirements.txt

# Run migrations/table creation & Seed mock data
python seed.py

# Launch FastAPI development server
uvicorn app.main:app --reload --port 8000
```
The server will bind to `http://localhost:8000`. You can inspect documentation at `http://localhost:8000/docs`.

### 3. Local AI Setup (Ollama)

Ensure Ollama is installed on your local host system:
1. Run `ollama pull qwen3:8b` (or set `OLLAMA_MODEL` in `.env` to another pulled model, e.g. `qwen:7b`).
2. Verify Ollama is listening on port `11434` (default).
3. If the backend is running inside Docker, it automatically redirects requests to `host.docker.internal:11434` to communicate with the host's Ollama instance. If Ollama is offline, the backend executes a robust fallback heuristics ruleset to return high-fidelity SMT analysis and avoid app errors.

### 4. Running the Flutter App

Once the backend is online:

```bash
cd frontend

# Verify dependencies are fetched
flutter pub get

# Launch the app
flutter run
```

---

## Mock User Credentials (Seeded)

Use these credentials to instantly log into the platform dashboard during demos/evaluation:
- **Email**: `operator@tracex.com`
- **Password**: `Password123!`
