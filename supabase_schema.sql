-- Vidyasagar University SAR Web App - Supabase setup
-- Run this entire script in Supabase SQL Editor.
-- IMPORTANT: do not put the service_role key in the web app.

create extension if not exists pgcrypto;

create table if not exists public.sar_cycles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  cycle_index integer not null check (cycle_index between 1 and 5),
  cycle_name text not null,
  period text default '',
  note text default '',
  fields jsonb not null default '{}'::jsonb,
  api jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique(user_id, cycle_index)
);

create table if not exists public.sar_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  cycle_index integer not null check (cycle_index between 1 and 5),
  category text not null,
  field_key text not null,
  file_name text not null,
  storage_path text not null unique,
  mime_type text default 'application/octet-stream',
  size_bytes bigint default 0,
  created_at timestamptz not null default now()
);

alter table public.sar_cycles enable row level security;
alter table public.sar_documents enable row level security;

revoke all on table public.sar_cycles from anon;
revoke all on table public.sar_documents from anon;
grant select, insert, update, delete on table public.sar_cycles to authenticated;
grant select, insert, update, delete on table public.sar_documents to authenticated;

-- Institution-wide authenticated access: every signed-in SAR user can see/edit SAR records.
-- If you want private per-user records later, change these policies to user_id = auth.uid().
drop policy if exists "authenticated users can read SAR cycles" on public.sar_cycles;
create policy "authenticated users can read SAR cycles"
on public.sar_cycles for select to authenticated using (true);

drop policy if exists "authenticated users can insert SAR cycles" on public.sar_cycles;
create policy "authenticated users can insert SAR cycles"
on public.sar_cycles for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "authenticated users can update SAR cycles" on public.sar_cycles;
create policy "authenticated users can update SAR cycles"
on public.sar_cycles for update to authenticated using (true) with check (auth.uid() = user_id);

drop policy if exists "authenticated users can delete SAR cycles" on public.sar_cycles;
create policy "authenticated users can delete SAR cycles"
on public.sar_cycles for delete to authenticated using (true);

drop policy if exists "authenticated users can read SAR documents" on public.sar_documents;
create policy "authenticated users can read SAR documents"
on public.sar_documents for select to authenticated using (true);

drop policy if exists "authenticated users can insert SAR documents" on public.sar_documents;
create policy "authenticated users can insert SAR documents"
on public.sar_documents for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "authenticated users can update SAR documents" on public.sar_documents;
create policy "authenticated users can update SAR documents"
on public.sar_documents for update to authenticated using (true) with check (auth.uid() = user_id);

drop policy if exists "authenticated users can delete SAR documents" on public.sar_documents;
create policy "authenticated users can delete SAR documents"
on public.sar_documents for delete to authenticated using (true);

-- Storage bucket for supporting documents.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'sar-documents',
  'sar-documents',
  false,
  52428800,
  array[
    'application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint','application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'image/jpeg','image/png'
  ]
)
on conflict (id) do nothing;

-- Storage access for authenticated users. Objects are stored under user-id/cycle/category/uuid_filename.
drop policy if exists "authenticated SAR users can upload documents" on storage.objects;
create policy "authenticated SAR users can upload documents"
on storage.objects for insert to authenticated
with check (bucket_id = 'sar-documents' and (storage.foldername(name))[1] = (select auth.uid()::text));

drop policy if exists "authenticated SAR users can read documents" on storage.objects;
create policy "authenticated SAR users can read documents"
on storage.objects for select to authenticated
using (bucket_id = 'sar-documents');

drop policy if exists "authenticated SAR users can update documents" on storage.objects;
create policy "authenticated SAR users can update documents"
on storage.objects for update to authenticated
using (bucket_id = 'sar-documents' and owner_id = (select auth.uid()::text))
with check (bucket_id = 'sar-documents' and owner_id = (select auth.uid()::text));

drop policy if exists "authenticated SAR users can delete documents" on storage.objects;
create policy "authenticated SAR users can delete documents"
on storage.objects for delete to authenticated
using (bucket_id = 'sar-documents' and owner_id = (select auth.uid()::text));

-- Helpful indexes
create index if not exists sar_cycles_user_idx on public.sar_cycles(user_id, cycle_index);
create index if not exists sar_documents_user_cycle_idx on public.sar_documents(user_id, cycle_index);
