-- BaariBaari: run in Supabase > SQL Editor (idempotent; v2 adds plan kinds + saved family plans)
create table if not exists public.plans (
  id            bigint generated always as identity primary key,
  created_at    timestamptz not null default now(),
  visitor_hash  text,            -- salted SHA-256 of IP, truncated; used only for the per-day cap
  input         jsonb not null,  -- fixed-field choices only; free-text note is never stored
  output        text,            -- raw Gemini JSON reply
  input_tokens  int,
  output_tokens int,
  refused       boolean not null default false,
  siblings      int,
  tasks_total   int,
  tasks_remote  int,
  language      text,
  model         text,
  latency_ms    int
);
alter table public.plans add column if not exists kind text not null default 'draft'; -- draft | update
create index if not exists plans_visitor_idx on public.plans (visitor_hash, created_at);
alter table public.plans enable row level security;

-- Saved family plans: the agreed split, shareable by an 8-character code. No names, no health data.
create table if not exists public.saved_plans (
  code       text primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  status     text not null default 'proposed',   -- proposed | agreed
  versions   int not null default 1,
  plan       jsonb not null
);
alter table public.saved_plans enable row level security;

-- Numbers the page shows back (first drafts only, so edits are not double-counted)
drop view if exists public.plan_stats;
create view public.plan_stats with (security_invoker = true) as
select count(*) filter (where not refused and kind = 'draft')                       as plans,
       (select count(*) from public.saved_plans)                                    as saved,
       coalesce(sum(tasks_total)  filter (where not refused and kind = 'draft'), 0) as tasks_total,
       coalesce(sum(tasks_remote) filter (where not refused and kind = 'draft'), 0) as tasks_remote
from public.plans;

create or replace view public.top_need with (security_invoker = true) as
select n as need, count(*) as times
from public.plans, jsonb_array_elements_text(input->'needs') as n
where not refused and kind = 'draft'
group by n
order by times desc, n
limit 1;
