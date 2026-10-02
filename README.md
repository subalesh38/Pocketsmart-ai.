# PocketSmart AI

> **AI-powered budget planning assistant** — plan your home furnishings, parties, and jewelry purchases in Indian Rupees, powered by Google Gemini.

---

## Table of Contents

1. [What is PocketSmart AI?](#what-is-pocketsmart-ai)
2. [Features](#features)
3. [Tech Stack](#tech-stack)
4. [Project Structure](#project-structure)
5. [Architecture Overview](#architecture-overview)
6. [Getting Started (Local Development)](#getting-started-local-development)
7. [Environment Variables](#environment-variables)
8. [API Reference](#api-reference)
9. [Frontend Pages and Components](#frontend-pages-and-components)
10. [AI / Gemini Integration](#ai--gemini-integration)
11. [Database](#database)
12. [Authentication](#authentication)
13. [Testing](#testing)
14. [Production Build](#production-build)
15. [Deployment on Render](#deployment-on-render)
16. [Security Notes](#security-notes)
17. [Known Limitations](#known-limitations)

---

## What is PocketSmart AI?

PocketSmart AI is a full-stack web application that uses **Google Gemini** to generate personalised budget plans for three domains:

| Planner | What it does |
|---------|-------------|
| Home | Allocates a budget across rooms (furniture, appliances, decor) with tier switching |
| Party | Plans a party/event with per-guest cost, venue suggestions and a day-of checklist |
| Jewelry | Recommends jewelry pieces with optional outfit image analysis for style matching |

All plans are saved to the user's history, can be reviewed later, and support **tier switching** (economy / standard / premium) without re-running Gemini.

---

## Features

- User registration and login (JWT via HTTP-only cookie)
- Three AI-powered planners: Home, Party, Jewelry
- Outfit image upload for Jewelry (JPEG / PNG / WebP, max 5 MB)
- Real-time budget pie chart and allocation table
- Tier switching (economy / standard / premium) with instant recalculation
- BUDGET_TOO_LOW fallback with minimum budget shown in INR
- Saved plan history with pagination and full detail view
- Dashboard with recent activity
- Responsive design verified at 375 px, 768 px, and 1280 px
- INR formatting throughout (en-IN locale)
- Rate limiting on auth and planning endpoints
- Structured JSON logging — no secrets in logs
- Production-ready SPA served directly from FastAPI

---

## Tech Stack

### Backend

| Layer | Technology |
|-------|-----------|
| Web framework | FastAPI (Python 3.11) |
| ORM | SQLAlchemy 2 |
| Database | SQLite (dev) / PostgreSQL (production) |
| Migrations | Alembic |
| AI | Google Gemini via google-genai SDK |
| Auth | JWT (PyJWT) + bcrypt password hashing |
| Image processing | Pillow |
| ASGI server | Uvicorn |

### Frontend

| Layer | Technology |
|-------|-----------|
| Framework | React 19 + TypeScript |
| Build tool | Vite 8 |
| Routing | React Router 7 |
| Styling | Tailwind CSS 4 |
| Charts | Recharts |
| Icons | Lucide React |

---

## Project Structure

```
pocketsmart-ai/
|-- backend/
|   |-- app/
|   |   |-- core/
|   |   |   |-- config.py          # All env-var settings (Pydantic Settings)
|   |   |   |-- deps.py            # FastAPI dependency injectors (auth, db)
|   |   |   |-- errors.py          # AppError + global exception handler
|   |   |   |-- logging.py         # Structured JSON logging middleware
|   |   |   |-- rate_limit.py      # In-memory rate limiter
|   |   |   `-- security.py        # JWT create / decode
|   |   |-- db/
|   |   |   |-- repository.py      # CRUD helpers
|   |   |   `-- session.py         # SQLAlchemy engine + SessionLocal
|   |   |-- models/
|   |   |   |-- user.py            # User ORM model
|   |   |   `-- plan.py            # Plan ORM model
|   |   |-- routes/
|   |   |   |-- auth.py            # /api/auth/*
|   |   |   |-- planners.py        # /api/plan/*
|   |   |   `-- history.py         # /api/history/*
|   |   |-- schemas/               # Pydantic request/response schemas
|   |   |-- services/
|   |   |   |-- auth.py
|   |   |   |-- budget_engine.py   # Tier recalculation
|   |   |   |-- fallbacks.py       # Fallback plans
|   |   |   |-- gemini_client.py   # Gemini API wrapper with retry
|   |   |   |-- links.py           # Purchase link generation
|   |   |   |-- planner_service.py # Orchestrates Gemini -> fallback
|   |   |   `-- prompts/           # Per-planner prompt builders
|   |   `-- main.py                # App factory, middleware, SPA serving
|   |-- migrations/
|   |-- scripts/
|   |   `-- prompt_eval.py         # Offline Gemini quality evaluation
|   |-- tests/                     # 53 tests, ~90% coverage
|   |-- .env.example
|   |-- alembic.ini
|   `-- requirements.txt
|
|-- src/                           # React frontend
|   |-- api/
|   |   |-- client.ts              # Fetch wrapper
|   |   |-- auth.ts
|   |   |-- plan.ts
|   |   `-- history.ts
|   |-- components/
|   |   |-- charts/                # Budget pie chart
|   |   |-- layout/                # Navbar, Sidebar, AppShell
|   |   |-- plan/                  # Shared result components
|   |   `-- ui/                    # Reusable UI primitives
|   |-- context/
|   |   `-- AuthContext.tsx
|   |-- pages/
|   |   |-- LandingPage.tsx
|   |   |-- AuthPage.tsx
|   |   |-- DashboardPage.tsx
|   |   |-- HomePlannerPage.tsx
|   |   |-- PartyPlannerPage.tsx
|   |   |-- JewelryPlannerPage.tsx
|   |   |-- HistoryPage.tsx
|   |   |-- PlanDetailPage.tsx
|   |   |-- ProfilePage.tsx
|   |   `-- SettingsPage.tsx
|   |-- types/
|   |-- App.tsx
|   `-- main.tsx
|
|-- dist/                          # Built frontend (served by FastAPI)
|-- docs/
|   |-- DEPLOY.md
|   |-- RUNNING.md
|   |-- README_DEVELOPER.md
|   `-- README_PROJECT.md
|-- render.yaml                    # Render infrastructure blueprint
|-- render-build.sh
|-- .python-version                # 3.11.10
|-- package.json
`-- vite.config.ts
```

---

## Architecture Overview

```
Browser (React SPA)
        |
        |  HTTP (cookie-authenticated JSON / multipart)
        v
FastAPI  (/api/*)
  |-- Auth routes      -->  JWT cookie set/cleared
  |-- Planner routes   -->  PlannerService --> GeminiClient --> BudgetEngine
  |                                        --> FallbackService (on error)
  |-- History routes   -->  Repository (SQLAlchemy)
  `-- SPA fallback     -->  serves dist/index.html for any non-/api GET
        |
        v
SQLite (dev) / PostgreSQL (production)
        |
        v
Google Gemini API   (never called from the browser)
```

**Key design decisions:**

- Gemini is called **only from the backend**. The API key never reaches the browser.
- The frontend is a compiled SPA served directly by FastAPI, enabling a **single-URL, single-service deployment**.
- Plans are persisted immediately after Gemini responds so history is never lost.
- Tier switching recalculates totals in-process — no additional Gemini call needed.

---

## Getting Started (Local Development)

### Prerequisites

| Tool | Minimum version |
|------|----------------|
| Python | 3.11 |
| Node.js | 18 |
| npm | 9 |

### 1 — Set up the backend

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS / Linux
source venv/bin/activate

pip install -r requirements.txt
```

### 2 — Configure environment variables

```bash
cp backend/.env.example backend/.env
```

Open `backend/.env` and set at minimum:

```env
GOOGLE_API_KEY=your_key_here
GEMINI_MODEL=gemini-2.5-flash
```

### 3 — Run database migrations

```bash
cd backend
alembic upgrade head
```

### 4 — Start the backend

```bash
# Windows (from the backend/ directory)
$env:PYTHONPATH="."; python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload

# macOS / Linux
PYTHONPATH=. uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

API live at `http://127.0.0.1:8000`.
Interactive docs at `http://127.0.0.1:8000/docs`.

### 5 — Start the frontend dev server

In a second terminal from the project root:

```bash
npm install
npm run dev
```

Frontend dev server runs at `http://localhost:5173` and proxies `/api` to port 8000.

### 6 — Production-like single-URL mode

```bash
npm run build        # outputs to dist/
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Visit `http://127.0.0.1:8000`.

---

## Environment Variables

All variables are loaded from `backend/.env` (or system environment in production).

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GOOGLE_API_KEY` | Yes | `""` | Google AI / Gemini API key |
| `GEMINI_MODEL` | No | `gemini-2.5-flash` | Gemini model ID |
| `SECRET_KEY` | Yes (prod) | dev default | JWT signing key — min 32 chars in production |
| `DATABASE_URL` | No | `sqlite:///./pocketsmart.db` | SQLAlchemy connection string |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | No | `30` | Session cookie lifetime in minutes |
| `ALLOWED_ORIGINS` | No | localhost variants | Comma-separated CORS origins |
| `MAX_UPLOAD_MB` | No | `5` | Maximum image upload size in MB |
| `COOKIE_SECURE` | No | `false` | Set `true` in production (requires HTTPS) |
| `RATE_LIMIT_ENABLED` | No | `true` | Enable in-memory rate limiting |
| `FRONTEND_DIST_DIR` | No | auto-detected | Override path to `dist/` folder |

---

## API Reference

### Authentication — `/api/auth`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/auth/register` | No | Create account — body: `{name, email, password}` |
| POST | `/api/auth/login` | No | Login — sets `access_token` cookie |
| POST | `/api/auth/logout` | Yes | Clears the session cookie |
| GET | `/api/auth/me` | Yes | Returns current user info |

### Planners — `/api/plan`

| Method | Path | Auth | Body | Description |
|--------|------|------|------|-------------|
| POST | `/api/plan/home` | Yes | JSON | Generate home budget plan |
| POST | `/api/plan/party` | Yes | JSON | Generate party budget plan |
| POST | `/api/plan/jewelry` | Yes | Multipart form | Generate jewelry plan (optional image) |
| POST | `/api/plan/{id}/recalculate` | Yes | `{item_id, tier}` | Switch tier on a saved plan |

**Home plan body:**
```json
{
  "total_budget": 500000,
  "rooms": "living room, bedroom, kitchen",
  "city": "Mumbai",
  "style": "modern",
  "priorities": "comfort",
  "notes": ""
}
```

**Party plan body:**
```json
{
  "total_budget": 100000,
  "guests": 50,
  "event_type": "wedding",
  "city": "Delhi",
  "preferences": "outdoor",
  "notes": ""
}
```

**Jewelry plan fields (multipart):**
```
total_budget   int     INR 1,000 to 1,00,00,000
occasion       string
preferences    string  (style description)
notes          string  (optional)
image          file    (optional — JPEG/PNG/WebP, max 5 MB)
```

**Plan response (all planners):**
```json
{
  "plan_id": "uuid",
  "total_budget": 500000,
  "allocated": 480000,
  "remaining": 20000,
  "status": "ok",
  "fallback": false,
  "items": [
    {
      "id": "uuid",
      "category": "Living Room",
      "name": "Sofa Set",
      "economy": 25000,
      "standard": 45000,
      "premium": 90000,
      "selected_tier": "standard",
      "cost": 45000,
      "links": []
    }
  ],
  "notes": "...",
  "party_extras": {},
  "jewelry_extras": {}
}
```

**Error response:**
```json
{
  "error": {
    "code": "BUDGET_TOO_LOW",
    "message": "Minimum budget for a home plan is Rs. 50,000",
    "details": { "minimum": 50000 }
  }
}
```

### History — `/api/history`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/history` | Yes | Paginated list (`?limit=10&offset=0`) |
| GET | `/api/history/recent` | Yes | Latest 3 plans (used by the Dashboard) |
| GET | `/api/history/{id}` | Yes | Full plan detail |

### System

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check — `{"status": "ok"}` |
| GET | `/docs` | Swagger UI |
| GET | `/redoc` | ReDoc UI |

---

## Frontend Pages and Components

### Pages

| Page | Route | Access | Description |
|------|-------|--------|-------------|
| Landing | `/` | Public | Hero, features, sample testimonials |
| Login / Register | `/login`, `/register` | Public | Auth forms |
| Dashboard | `/dashboard` | Protected | Welcome + planner shortcuts + recent activity |
| Home Planner | `/recommendations/home` | Protected | Home budget planner |
| Party Planner | `/recommendations/party` | Protected | Party planner |
| Jewelry Planner | `/recommendations/jewelry` | Protected | Jewelry planner with image upload |
| History | `/history` | Protected | Paginated plan history list |
| Plan Detail | `/history/:id` | Protected | Full plan with tier switching |
| Profile | `/profile` | Protected | User profile |
| Settings | `/settings` | Protected | App settings |

### Shared Result Components (`src/components/plan/`)

Reused across all planner pages and the Plan Detail page:

| Component | Purpose |
|-----------|---------|
| `BudgetSummaryCard` | Total / allocated / remaining in INR |
| `BudgetPieChart` | Interactive pie chart (Recharts) |
| `AllocationTable` | Per-item breakdown with tier selector |
| `TierSelector` | Economy / standard / premium toggle |
| `FallbackBanner` | Warning shown when Gemini fallback is active |
| `BudgetTooLowCard` | Error card for BUDGET_TOO_LOW responses |
| `LoadingSkeleton` | Animated placeholder while the API call is in-flight |

---

## AI / Gemini Integration

### Request flow

1. User submits a planner form
2. Frontend POSTs to the relevant `/api/plan/*` endpoint
3. Backend builds a structured prompt (`services/prompts/`)
4. `GeminiClient` sends the prompt (plus optional image bytes) to Gemini
5. Gemini responds with JSON matching the `PlanResult` schema
6. `PlannerService` validates the JSON; on failure the `FallbackService` is used
7. Plan is saved to the database and returned to the browser

### Fallback behaviour

| Trigger | Outcome |
|---------|---------|
| Gemini API error | Pre-built fallback plan, `fallback: true` in response |
| Budget below minimum | `BUDGET_TOO_LOW` error with minimum amount in INR |
| Invalid JSON after retry | Fallback plan returned |

### Model selection

Set `GEMINI_MODEL` to the model ID available on your API key. Use `gemini-2.5-flash` for the best speed-to-quality ratio.

To list models available on your key:

```bash
python -c "
from google import genai
client = genai.Client(api_key='YOUR_KEY')
[print(m.name) for m in client.models.list()]
"
```

---

## Database

### users table

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| name | String | |
| email | String | Unique |
| password_hash | String | bcrypt |
| created_at | DateTime | |

### plans table

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | Foreign key to users |
| type | String | home, party, or jewelry |
| input_json | JSON | Raw form inputs |
| result_json | JSON | Full Gemini or fallback plan |
| total_budget | Integer | INR |
| allocated | Integer | INR |
| remaining | Integer | INR |
| has_image | Boolean | |
| created_at | DateTime | |

### Migrations

```bash
# Apply all pending migrations
cd backend && alembic upgrade head

# Create a migration after model changes
alembic revision --autogenerate -m "describe change"
```

SQLite in development. PostgreSQL in production — the app translates `postgres://` to `postgresql+psycopg://` automatically (Render compatibility).

---

## Authentication

- Passwords hashed with **bcrypt**
- Sessions use **JWT** stored in an **HTTP-only, SameSite=Lax** cookie
- Cookie is `Secure=true` when `COOKIE_SECURE=true`
- Token expiry defaults to 30 minutes (`ACCESS_TOKEN_EXPIRE_MINUTES`)
- **Startup check:** if `COOKIE_SECURE=true` and `SECRET_KEY` is absent or shorter than 32 characters, the server refuses to start

---

## Testing

### Run the full suite

```bash
cd backend
venv\Scripts\activate     # Windows

pytest tests/ -v --tb=short
```

### Check coverage

```bash
pytest tests/ --cov=app --cov-report=term-missing
```

Current coverage: approximately **90%** across `services/` and `routes/`.

### Test inventory

| File | Coverage area |
|------|--------------|
| `test_auth.py` | Register, login, logout, JWT |
| `test_planners.py` | Home, party, jewelry endpoints |
| `test_planners_ext.py` | Edge cases, invalid inputs, image validation |
| `test_budget_engine.py` | Tier switching, recalculation |
| `test_history.py` | History list, recent, detail |
| `test_gemini_client.py` | Retry and error handling |
| `test_planner_service.py` | Orchestration with mocked Gemini |
| `test_db.py` | Repository CRUD |
| `test_production_spa.py` | SPA static serving and fallback route |
| `test_services_ext.py` | Links service, auth helpers |

### Offline Gemini quality evaluation

```bash
cd backend
python scripts/prompt_eval.py
```

Reports valid JSON rate, plans within budget, fallback usage, and average latency across approximately 8 realistic inputs per planner. Requires a real `GOOGLE_API_KEY`.

---

## Production Build

```bash
# Build the frontend
npm run build

# Serve with FastAPI
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Open `http://127.0.0.1:8000` — full app served from one URL and one process.

---

## Deployment on Render

The project ships with `render.yaml` for one-click deployment.

### Steps

1. Push to GitHub
2. Render dashboard: **New > Blueprint** > select repo
3. Render provisions a PostgreSQL database and a Web Service
4. Add `GOOGLE_API_KEY` in the Render dashboard under **Environment > Secrets**
5. Deploy

### Variables managed by render.yaml

| Variable | Source |
|----------|--------|
| `DATABASE_URL` | Auto-linked from Render PostgreSQL |
| `SECRET_KEY` | Auto-generated by Render |
| `GEMINI_MODEL` | `gemini-2.5-flash` |
| `COOKIE_SECURE` | `true` |
| `ALLOWED_ORIGINS` | `https://pocketsmart-ai.onrender.com` |
| `GOOGLE_API_KEY` | Must be added manually |

### Build pipeline

```
render-build.sh
  - pip install -r backend/requirements.txt
  - npm ci && npm run build

Pre-deploy:  cd backend && alembic upgrade head
Start:       cd backend && uvicorn app.main:app --host 0.0.0.0 --port $PORT
Health:      GET /health
```

See [docs/DEPLOY.md](docs/DEPLOY.md) for full step-by-step instructions.

---

## Security Notes

| Concern | How it is handled |
|---------|------------------|
| API key exposure | Gemini called backend-only; key never reaches the browser |
| Secrets in VCS | `.env` is git-ignored; only `.env.example` is committed |
| Wildcard CORS | Startup raises RuntimeError if `*` appears in `ALLOWED_ORIGINS` |
| Weak secret key | Startup blocked if `COOKIE_SECURE=true` and key < 32 chars |
| Password storage | bcrypt with auto-generated salt |
| Cookie | HttpOnly, SameSite=Lax, Secure=true in production |
| Rate limiting | In-memory limiter on `/api/auth/*` and `/api/plan/*` |
| Image validation | Pillow server-side verification, not just MIME sniffing |
| SQL injection | SQLAlchemy ORM parameterised queries |

---

## Known Limitations

- **Rate limiter is in-memory** — resets on restart, not shared across instances. Replace with Redis for high-traffic production.
- **SQLite in development** — not suitable for concurrent production writes.
- **No email verification** — users are active immediately after registration.
- **Images not persisted** — outfit photos are analysed by Gemini but not stored.
- **Single-region** — no CDN or geo-distribution by default.

---

## Useful Local Commands

```bash
# Reset development database
Remove-Item backend\pocketsmart.db
cd backend && alembic upgrade head

# Rebuild frontend after source changes
npm run build

# Run a single backend test
cd backend && pytest tests/test_planners.py -v

# Start backend with auto-reload (development)
$env:PYTHONPATH="."; python -m uvicorn app.main:app --reload --port 8000
```

---

*Built with FastAPI, React, and Google Gemini.*
