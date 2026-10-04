# BaariBaari — Care, turn by turn, together

Live: https://baaribaari.vercel.app · ISB GenAI individual assignment (Tasks 3–4).

**AI proposes → family decides.** Siblings describe where each lives, when they're free, the time and money each can offer and how they like to help, plus what their parent needs. Gemini suggests a starting split with a one-line reason per sibling; the family moves tasks, the AI re-explains its reasons and rewrites the WhatsApp message for the locked assignment, and the family saves the plan (shareable link, proposed → agreed).

## Architecture
```
Family ─▶ index.html (Vercel) ─▶ /api/plan (Vercel serverless)
                                   1 validate allowlisted fields · per-visitor cap · cost split      [deterministic]
                                   2 Gemini 3.5 Flash-Lite: split + why + message (JSON schema)     [generative]
                                   3 coverage · care load · in-person check · Hindi script check    [deterministic]
                                   4 log exchange · save plan · aggregate read-back                 [persistent: Supabase]
```
- `api/plan.js` — modes `draft`, `update` (assignment locked, AI only re-explains), `save` (no AI); `GET ?code=` loads a saved plan; `GET` returns the read-back numbers.
- Care load = times/month × hours × effort (2 for in-person tasks) — default weights, directional.
- Hindi: if the message is < 60% Devanagari, one automatic repair call; otherwise flagged.
- `schema.sql` — `plans` (every AI exchange, with `kind`), `saved_plans`, views `plan_stats`, `top_need`. RLS on, no public policies.

## Environment variables (Vercel → Settings → Environment Variables)
`GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`. No key is stored in this repository.

## Guardrails
Allowlisted inputs only (refused before Gemini is called); refusal rule for medical/legal/financial advice; the free-text note is untrusted and never stored; no names; 450 max output tokens; 8 AI calls per visitor per 24 h.
