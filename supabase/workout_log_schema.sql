-- BodyBuddy workout log tables.
-- Run this in the Supabase SQL editor before using the Exercise Log persistence.
--
-- If a previous failed run partially created these tables, run this reset block first:
-- drop table if exists public.workout_sets cascade;
-- drop table if exists public.workout_cardio_laps cascade;
-- drop table if exists public.workout_exercises cascade;
-- drop table if exists public.workout_sessions cascade;

create table if not exists public.user_exercises (
    id uuid primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    name text not null,
    muscle_groups text[] not null default '{}',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.workout_sessions (
    id uuid primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null default 'New Session',
    session_date timestamptz not null,
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.workout_exercises (
    id uuid primary key,
    session_id uuid not null references public.workout_sessions(id) on delete cascade,
    name text not null default 'New Exercise',
    exercise_type text not null default 'lifting',
    notes text,
    position integer not null default 0,
    duration_minutes numeric,
    distance numeric,
    duration_seconds integer,
    distance_meters numeric,
    distance_unit text not null default 'mi',
    calories_burned numeric,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.workout_sets (
    id uuid primary key,
    exercise_id uuid not null references public.workout_exercises(id) on delete cascade,
    set_number integer not null default 0,
    reps numeric,
    weight numeric,
    rpe numeric,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.workout_cardio_laps (
    id uuid primary key,
    exercise_id uuid not null references public.workout_exercises(id) on delete cascade,
    lap_number integer not null default 0,
    distance numeric,
    time_minutes numeric,
    distance_meters numeric,
    distance_unit text not null default 'mi',
    time_seconds integer,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.workout_sets
    alter column reps type numeric using reps::numeric,
    alter column weight type numeric using weight::numeric;

alter table public.workout_exercises
    add column if not exists exercise_type text not null default 'lifting',
    add column if not exists duration_minutes numeric,
    add column if not exists distance numeric,
    add column if not exists duration_seconds integer,
    add column if not exists distance_meters numeric,
    add column if not exists distance_unit text not null default 'mi',
    add column if not exists calories_burned numeric;

alter table public.workout_cardio_laps
    add column if not exists distance_meters numeric,
    add column if not exists distance_unit text not null default 'mi',
    add column if not exists time_seconds integer;

alter table public.workout_exercises
    drop constraint if exists workout_exercises_exercise_type_check;

alter table public.workout_exercises
    add constraint workout_exercises_exercise_type_check
    check (exercise_type in ('lifting', 'cardio'));

alter table public.workout_exercises
    drop constraint if exists workout_exercises_distance_unit_check;

alter table public.workout_exercises
    add constraint workout_exercises_distance_unit_check
    check (distance_unit in ('mi', 'km', 'm'));

alter table public.workout_cardio_laps
    drop constraint if exists workout_cardio_laps_distance_unit_check;

alter table public.workout_cardio_laps
    add constraint workout_cardio_laps_distance_unit_check
    check (distance_unit in ('mi', 'km', 'm'));

create unique index if not exists user_exercises_user_name_idx
    on public.user_exercises(user_id, lower(name));

create index if not exists workout_sessions_user_date_idx
    on public.workout_sessions(user_id, session_date desc);

create index if not exists workout_exercises_session_position_idx
    on public.workout_exercises(session_id, position);

create index if not exists workout_sets_exercise_number_idx
    on public.workout_sets(exercise_id, set_number);

create index if not exists workout_cardio_laps_exercise_number_idx
    on public.workout_cardio_laps(exercise_id, lap_number);

alter table public.user_exercises enable row level security;
alter table public.workout_sessions enable row level security;
alter table public.workout_exercises enable row level security;
alter table public.workout_sets enable row level security;
alter table public.workout_cardio_laps enable row level security;

drop policy if exists "Users can read their exercise library" on public.user_exercises;
create policy "Users can read their exercise library"
on public.user_exercises
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert their exercise library" on public.user_exercises;
create policy "Users can insert their exercise library"
on public.user_exercises
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update their exercise library" on public.user_exercises;
create policy "Users can update their exercise library"
on public.user_exercises
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their exercise library" on public.user_exercises;
create policy "Users can delete their exercise library"
on public.user_exercises
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can read their workout sessions" on public.workout_sessions;
create policy "Users can read their workout sessions"
on public.workout_sessions
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert their workout sessions" on public.workout_sessions;
create policy "Users can insert their workout sessions"
on public.workout_sessions
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update their workout sessions" on public.workout_sessions;
create policy "Users can update their workout sessions"
on public.workout_sessions
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their workout sessions" on public.workout_sessions;
create policy "Users can delete their workout sessions"
on public.workout_sessions
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can read their workout exercises" on public.workout_exercises;
create policy "Users can read their workout exercises"
on public.workout_exercises
for select
to authenticated
using (
    exists (
        select 1
        from public.workout_sessions
        where workout_sessions.id = session_id
        and workout_sessions.user_id = auth.uid()
    )
);

drop policy if exists "Users can insert their workout exercises" on public.workout_exercises;
create policy "Users can insert their workout exercises"
on public.workout_exercises
for insert
to authenticated
with check (
    exists (
        select 1
        from public.workout_sessions
        where workout_sessions.id = session_id
        and workout_sessions.user_id = auth.uid()
    )
);

drop policy if exists "Users can update their workout exercises" on public.workout_exercises;
create policy "Users can update their workout exercises"
on public.workout_exercises
for update
to authenticated
using (
    exists (
        select 1
        from public.workout_sessions
        where workout_sessions.id = session_id
        and workout_sessions.user_id = auth.uid()
    )
)
with check (
    exists (
        select 1
        from public.workout_sessions
        where workout_sessions.id = session_id
        and workout_sessions.user_id = auth.uid()
    )
);

drop policy if exists "Users can delete their workout exercises" on public.workout_exercises;
create policy "Users can delete their workout exercises"
on public.workout_exercises
for delete
to authenticated
using (
    exists (
        select 1
        from public.workout_sessions
        where workout_sessions.id = session_id
        and workout_sessions.user_id = auth.uid()
    )
);

drop policy if exists "Users can read their workout sets" on public.workout_sets;
create policy "Users can read their workout sets"
on public.workout_sets
for select
to authenticated
using (
    exists (
        select 1
        from public.workout_exercises
        join public.workout_sessions
            on workout_sessions.id = workout_exercises.session_id
        where workout_exercises.id = exercise_id
        and workout_sessions.user_id = auth.uid()
    )
);

drop policy if exists "Users can insert their workout sets" on public.workout_sets;
create policy "Users can insert their workout sets"
on public.workout_sets
for insert
to authenticated
with check (
    exists (
        select 1
        from public.workout_exercises
        join public.workout_sessions
            on workout_sessions.id = workout_exercises.session_id
        where workout_exercises.id = exercise_id
        and workout_sessions.user_id = auth.uid()
    )
);

drop policy if exists "Users can update their workout sets" on public.workout_sets;
create policy "Users can update their workout sets"
on public.workout_sets
for update
to authenticated
using (
    exists (
        select 1
        from public.workout_exercises
        join public.workout_sessions
            on workout_sessions.id = workout_exercises.session_id
        where workout_exercises.id = exercise_id
        and workout_sessions.user_id = auth.uid()
    )
)
with check (
    exists (
        select 1
        from public.workout_exercises
        join public.workout_sessions
            on workout_sessions.id = workout_exercises.session_id
        where workout_exercises.id = exercise_id
        and workout_sessions.user_id = auth.uid()
    )
);

drop policy if exists "Users can delete their workout sets" on public.workout_sets;
create policy "Users can delete their workout sets"
on public.workout_sets
for delete
to authenticated
using (
    exists (
        select 1
        from public.workout_exercises
        join public.workout_sessions
            on workout_sessions.id = workout_exercises.session_id
        where workout_exercises.id = exercise_id
        and workout_sessions.user_id = auth.uid()
    )
);

drop policy if exists "Users can read their cardio laps" on public.workout_cardio_laps;
create policy "Users can read their cardio laps"
on public.workout_cardio_laps
for select
to authenticated
using (
    exists (
        select 1
        from public.workout_exercises
        join public.workout_sessions
            on workout_sessions.id = workout_exercises.session_id
        where workout_exercises.id = exercise_id
        and workout_sessions.user_id = auth.uid()
    )
);

drop policy if exists "Users can insert their cardio laps" on public.workout_cardio_laps;
create policy "Users can insert their cardio laps"
on public.workout_cardio_laps
for insert
to authenticated
with check (
    exists (
        select 1
        from public.workout_exercises
        join public.workout_sessions
            on workout_sessions.id = workout_exercises.session_id
        where workout_exercises.id = exercise_id
        and workout_sessions.user_id = auth.uid()
    )
);

drop policy if exists "Users can update their cardio laps" on public.workout_cardio_laps;
create policy "Users can update their cardio laps"
on public.workout_cardio_laps
for update
to authenticated
using (
    exists (
        select 1
        from public.workout_exercises
        join public.workout_sessions
            on workout_sessions.id = workout_exercises.session_id
        where workout_exercises.id = exercise_id
        and workout_sessions.user_id = auth.uid()
    )
)
with check (
    exists (
        select 1
        from public.workout_exercises
        join public.workout_sessions
            on workout_sessions.id = workout_exercises.session_id
        where workout_exercises.id = exercise_id
        and workout_sessions.user_id = auth.uid()
    )
);

drop policy if exists "Users can delete their cardio laps" on public.workout_cardio_laps;
create policy "Users can delete their cardio laps"
on public.workout_cardio_laps
for delete
to authenticated
using (
    exists (
        select 1
        from public.workout_exercises
        join public.workout_sessions
            on workout_sessions.id = workout_exercises.session_id
        where workout_exercises.id = exercise_id
        and workout_sessions.user_id = auth.uid()
    )
);
