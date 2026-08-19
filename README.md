# ReachInbox Email Scheduler

A production-oriented full-stack email scheduler using React, Express, TypeScript, MySQL, Prisma, Redis, BullMQ, and Ethereal SMTP.

## Implemented features

### Backend

- Express REST API with TypeScript and Zod validation.
- MySQL persistence through Prisma migrations.
- Google OAuth and cookie-based sessions.
- Sender management with ownership checks.
- Per-recipient scheduling with persistent BullMQ delayed jobs.
- Configurable worker concurrency.
- Redis-backed atomic hourly rate limiting across workers.
- Minimum delay support and hourly-limit rescheduling.
- SMTP delivery through Ethereal Email.
- BullMQ exponential retries for temporary failures.
- Persistent statuses: scheduled, processing, sent, failed.
- Unique idempotency keys and deterministic BullMQ job IDs.
- Health and queue statistics endpoints.
- Helmet, CORS, secure environment configuration, and JSON error responses.

### Frontend

- React/TypeScript responsive dashboard.
- Google sign-in page.
- Dashboard statistics and sender health.
- Scheduled and sent email views.
- Compose and scheduling flow.
- CSV-style recipient parsing, invalid email filtering, and duplicate removal.
- Scheduling review with delay, hourly limit, and estimated completion.
- Responsive SaaS design and status badges.

## Architecture

```mermaid
flowchart TD
  User[User] --> Web[React frontend]
  Web --> API[Express API]
  API --> DB[(MySQL / Prisma)]
  API --> Queue[BullMQ delayed jobs]
  Queue --> Redis[(Redis with AOF volume)]
  Redis --> Worker[Dedicated worker]
  Worker --> Limiter[Atomic Redis rate limiter]
  Worker --> SMTP[Ethereal SMTP]
```

The API creates durable MySQL state and BullMQ delayed jobs. The worker processes jobs independently and sends through Ethereal SMTP. No cron, polling scheduler, global setTimeout scheduler, or in-memory queue is used.

## Prerequisites

- Node.js 20+
- Docker Desktop with the Linux engine enabled
- Google Cloud OAuth credentials
- Ethereal Email credentials

## Quick start

From PowerShell:

```powershell
cd "D:\CLG\VS CODE\Outbox Assignment"
npm install
Copy-Item .env.example .env
docker compose up -d
npx prisma generate
npx prisma migrate dev --name init
```

Run the services in separate terminals:

```powershell
npm run dev:api
npm run dev:worker
npm run dev:web
```

Open [http://localhost:5173](http://localhost:5173).

Docker maps MySQL to host port `3307` because port `3306` may already be occupied by an existing MySQL installation. Redis uses port `6379`.

## Environment variables

```env
DATABASE_URL=mysql://reachinbox:reachinbox@localhost:3307/reachinbox
REDIS_URL=redis://localhost:6379
PORT=4000
FRONTEND_URL=http://localhost:5173
API_URL=http://localhost:4000
SESSION_SECRET=replace-with-a-long-random-secret

GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_CALLBACK_URL=http://localhost:4000/api/auth/google/callback

WORKER_CONCURRENCY=5
MAX_EMAILS_PER_HOUR=200
MIN_EMAIL_DELAY_MS=2000

ETHEREAL_HOST=smtp.ethereal.email
ETHEREAL_PORT=587
ETHEREAL_USER=
ETHEREAL_PASSWORD=
```

Never commit `.env`.

## Google OAuth

Create a Web application OAuth client in Google Cloud Console and add:

```text
http://localhost:4000/api/auth/google/callback
```

The callback exchanges the authorization code with Google, retrieves the profile, upserts the user in MySQL, creates a session, and redirects to the dashboard.

## Ethereal Email

1. Create an account at [Ethereal Email](https://ethereal.email/).
2. Copy the SMTP username and password into `.env`.
3. Add/configure an Ethereal sender.
4. Schedule a message.
5. Preview the captured message in the Ethereal inbox.

Ethereal is intended for testing and preview; messages are not delivered to the recipient's real inbox.

## Scheduling and persistence

For every recipient, the API:

1. Validates the request with Zod.
2. Creates an `EmailJob` row in MySQL.
3. Calculates `scheduledAt` using the requested delay.
4. Creates a BullMQ job with `delay = scheduledAt - Date.now()`.
5. Stores the BullMQ job ID in MySQL.

Future jobs remain in Redis and state remains in MySQL. API or worker restarts do not recreate or lose scheduled jobs. Docker Compose uses persistent MySQL and Redis volumes; Redis runs with AOF persistence.

For 1,000 messages scheduled at the same time, BullMQ retains all jobs, workers process concurrently, Redis controls shared sender capacity, and jobs that exceed the current hourly capacity are rescheduled rather than dropped.

## Rate limiting and concurrency

Each worker atomically increments:

```text
email-rate-limit:{senderId}:{hourWindow}
```

The count is compared to the configured hourly limit. Because the counter is in Redis, multiple workers share the same limit. When capacity is exhausted, the worker updates `scheduledAt` in MySQL and moves the BullMQ job to the next hour.

`WORKER_CONCURRENCY` controls parallel BullMQ processing without bypassing rate limits, idempotency, or job-state checks.

## Idempotency and delivery trade-off

Each job has a unique idempotency key and deterministic BullMQ ID. The worker skips jobs already marked `sent`. A crash after SMTP accepts a message but before MySQL updates remains an unavoidable at-least-once delivery boundary; persistent state checks, guarded updates, and finite retries minimize normal duplicates.

## API endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/health` | API, MySQL, and Redis status |
| GET | `/api/auth/me` | Current user |
| GET | `/api/auth/google` | Begin Google OAuth |
| GET | `/api/auth/google/callback` | Complete Google OAuth |
| POST | `/api/auth/logout` | End session |
| GET | `/api/senders` | List senders |
| POST | `/api/senders` | Add sender |
| DELETE | `/api/senders/:id` | Delete sender |
| POST | `/api/emails/schedule` | Schedule email jobs |
| GET | `/api/emails/scheduled` | Scheduled jobs |
| GET | `/api/emails/sent` | Sent jobs |
| GET | `/api/emails/:id` | Job detail |
| GET | `/api/queue/stats` | BullMQ counts |

## Demo video checklist

Keep the video under five minutes:

1. Show the private GitHub repository.
2. Show MySQL and Redis running with `docker compose ps`.
3. Start API, worker, and frontend.
4. Log in with Google.
5. Add an Ethereal sender.
6. Create scheduled emails or upload CSV data.
7. Show jobs in Scheduled Emails.
8. Show jobs moving to Sent Emails.
9. Preview a message in Ethereal.
10. Schedule a future email, stop/restart the worker, and show the job remains and sends.
11. Optionally demonstrate delay or hourly rate limiting.

## Verification

```powershell
npm run typecheck
npm run build
npx prisma validate
```

Health check:

```text
http://localhost:4000/api/health
```

## Assumptions, shortcuts, and trade-offs

- Ethereal is used for safe test SMTP delivery as requested by the assignment.
- MySQL host port is `3307` to avoid conflict with a local MySQL service on `3306`.
- Local cookie sessions should use HTTPS and secure cookies in production.
- Delivery is at-least-once around the SMTP/database commit boundary.
- Google and Ethereal credentials are supplied through environment variables.
- Persistence depends on the Docker volumes remaining available.

## Project structure

```text
apps/api       Express API, OAuth, routes, queue creation
apps/worker    BullMQ worker, rate limiter, SMTP delivery
apps/web       React dashboard and compose UI
prisma         MySQL schema and migrations
docker-compose.yml
.env.example
README.md
```

