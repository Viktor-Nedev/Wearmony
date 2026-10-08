-- Wearmony schema. Apply once: Supabase dashboard -> SQL Editor -> paste -> Run
-- (or `supabase db push`). Safe to re-run: every statement is idempotent.
--
-- Access model: row-level security is ON for every table and there are NO
-- policies, so the publishable key cannot read or write anything. Only the
-- backend (secret key) touches these tables, and it enforces who may see what.

create table if not exists public.events (
  id uuid primary key,
  name text not null check (char_length(name) between 1 and 80),
  template text not null check (template in ('prom', 'theatre', 'group')),
  organizer_id uuid not null,
  join_code text not null unique,
  budget_per_person numeric(12, 2) check (budget_per_person >= 0),
  budget_total numeric(12, 2) check (budget_total >= 0),
  currency text not null default 'EUR',
  demo boolean not null default false,
  created_at timestamptz not null default now()
);
-- Added after the first version; harmless when the column already exists.
alter table public.events add column if not exists event_date date;
alter table public.events add column if not exists dress_code text[] not null default '{}';
alter table public.events add column if not exists lock_by date;
create index if not exists events_organizer_idx on public.events (organizer_id);

create table if not exists public.participants (
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null,
  display_name text not null check (char_length(display_name) between 1 and 40),
  pair_with uuid,
  photo_path text,
  photo_hash text,
  photo_quality jsonb,
  pose text check (pose in ('standing', 'seated')),
  consent_at timestamptz,
  joined_at timestamptz not null default now(),
  primary key (event_id, user_id)
);
create index if not exists participants_user_idx on public.participants (user_id);

create table if not exists public.items (
  id uuid primary key,
  event_id uuid not null references public.events (id) on delete cascade,
  type text not null check (type in ('garment', 'makeup', 'hair')),
  name text not null check (char_length(name) between 1 and 80),
  price numeric(12, 2) not null default 0 check (price >= 0),
  category text check (category in ('full_body', 'upper_body', 'lower_body', 'outer')),
  image_path text,
  image_hash text,
  color_hex text check (color_hex ~ '^#[0-9A-Fa-f]{6}$'),
  dominant_colors jsonb,
  added_by text not null,
  vendor_name text,
  created_at timestamptz not null default now()
);
create index if not exists items_event_idx on public.items (event_id);

create table if not exists public.looks (
  event_id uuid not null,
  user_id uuid not null,
  garment_id uuid references public.items (id) on delete set null,
  makeup_id uuid references public.items (id) on delete set null,
  hair_id uuid references public.items (id) on delete set null,
  locked boolean not null default false,
  render_requested boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (event_id, user_id),
  foreign key (event_id, user_id) references public.participants (event_id, user_id) on delete cascade
);

create table if not exists public.renders (
  event_id uuid not null,
  hash text not null,
  user_id uuid not null,
  kind text not null check (kind in ('apparel', 'makeup', 'hair')),
  item_id uuid not null,
  input_path text not null,
  status text not null check (status in ('running', 'success', 'failed')),
  provider_task_id text,
  result_path text,
  failure_reason text,
  failure_message text,
  units numeric(8, 2) not null default 0,
  mock boolean not null default false,
  checks jsonb,
  checked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (event_id, hash),
  foreign key (event_id, user_id) references public.participants (event_id, user_id) on delete cascade
);

create table if not exists public.vendor_links (
  token_hash text primary key,
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid,
  scope text not null check (scope in ('look', 'hair', 'catalogue')),
  vendor_name text,
  created_by uuid not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  foreign key (event_id, user_id) references public.participants (event_id, user_id) on delete cascade
);
create index if not exists vendor_links_event_idx on public.vendor_links (event_id);

-- YouCam file ids by image content hash, so the same image is uploaded once.
create table if not exists public.provider_files (
  image_hash text primary key,
  file_id text not null,
  uploaded_at timestamptz not null default now()
);

-- "Ask the group": one open poll per participant over two or three catalogue garments.
-- Item ids are an array (no foreign key); the backend skips ids whose item was deleted.
create table if not exists public.polls (
  event_id uuid not null,
  user_id uuid not null,
  item_ids uuid[] not null,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id),
  foreign key (event_id, user_id) references public.participants (event_id, user_id) on delete cascade
);

create table if not exists public.poll_votes (
  event_id uuid not null,
  owner_id uuid not null,
  voter_id uuid not null,
  item_id uuid not null references public.items (id) on delete cascade,
  voted_at timestamptz not null default now(),
  primary key (event_id, owner_id, voter_id),
  foreign key (event_id, owner_id) references public.polls (event_id, user_id) on delete cascade,
  foreign key (event_id, voter_id) references public.participants (event_id, user_id) on delete cascade
);

alter table public.events enable row level security;
alter table public.participants enable row level security;
alter table public.items enable row level security;
alter table public.looks enable row level security;
alter table public.renders enable row level security;
alter table public.vendor_links enable row level security;
alter table public.provider_files enable row level security;
alter table public.polls enable row level security;
alter table public.poll_votes enable row level security;
