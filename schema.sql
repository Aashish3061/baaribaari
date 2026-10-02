-- BaariBaari: run once in Supabase > SQL Editor
create table if not exists public.plans (
  id            bigint generated always as identity primary key,
  created_at    timestamptz not null default now(),
  visitor_hash  text,            -- salted SHA-256 of IP, truncated; used only for the 3-per-day cap
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
create index if not exists plans_visitor_idx on public.plans (visitor_hash, created_at);

-- Row Level Security on, no policies: only the server-side secret key can read or write.
alter table public.plans enable row level security;

-- Numbers the page shows back
create or replace view public.plan_stats with (security_invoker = true) as
select count(*) filter (where not refused)                      as plans,
       coalesce(sum(siblings)     filter (where not refused), 0) as siblings,
       coalesce(sum(tasks_total)  filter (where not refused), 0) as tasks_total,
       coalesce(sum(tasks_remote) filter (where not refused), 0) as tasks_remote
from public.plans;

create or replace view public.top_need with (security_invoker = true) as
select n as need, count(*) as times
from public.plans, jsonb_array_elements_text(input->'needs') as n
where not refused
group by n
order by times desc, n
limit 1;
