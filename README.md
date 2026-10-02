# BaariBaari — Care, turn by turn, together

Landing page + live demo for an ISB GenAI assignment (Tasks 3–4). Live: https://baaribaari.vercel.app

Siblings describe who lives where, the time and money each can offer, and what their parent needs; BaariBaari drafts a gentle starting proposal for sharing the care plus a ready-to-send WhatsApp message.

## Stack
- `index.html` — single-page landing site (vanilla HTML/CSS/JS).
- `api/plan.js` — Vercel serverless function. `POST` validates the fixed fields, enforces a 5-plans-per-24h cap per visitor, computes cost shares in code, calls Gemini (`gemini-3.5-flash-lite`, 350 max output tokens, JSON schema output), logs the exchange to Supabase, and returns the plan. `GET` returns the aggregate numbers shown on the page.
- `schema.sql` — `plans` table (RLS on, no public policies) and the `plan_stats` / `top_need` views.

## Environment variables (Vercel → Settings → Environment Variables)
`GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`. No key is stored in this repository.

## Guardrails
- Allowlisted inputs only; anything else is refused before Gemini is called.
- System prompt refusal rule: no medical, medicine, dose, symptom, legal, tax or investment advice; the free-text note is treated as untrusted data.
- No names stored; the free-text note is never written to the database.
