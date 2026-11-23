-- =====================================================================
-- Rol "superusuario"  (mismos permisos que admin + interfaz con dashboard)
-- Ejecutar en Supabase > SQL Editor. Se puede ejecutar más de una vez.
-- Qué hace:
--  1) Permite el valor 'superusuario' en profiles.role (quita/recrea el CHECK).
--  2) Reescribe funciones y políticas RLS que dicen  role = 'admin'
--     para que también acepten 'superusuario'.
--  3) Crea un trigger: solo un superusuario puede asignar/quitar ese rol
--     (un admin NO puede ascenderse a sí mismo). Desde el SQL Editor sí se puede.
-- Al final devuelve una tabla con lo que aún menciona 'admin' sin 'superusuario'
-- (si sale vacía, todo quedó cubierto).
-- =====================================================================

create or replace function pg_temp.rw(t text) returns text language plpgsql as $f$
declare r text := t; c text := '(::(?:character varying|[a-z_."]+))?';
begin
  if r like '%superusuario%' then return r; end if;
  -- role <> 'admin'  /  != 'admin'
  r := regexp_replace(r, '(<>|!=)\s*''admin''' || c, ' NOT IN (''admin''\2, ''superusuario''\2)', 'gi');
  -- role = 'admin'   (sin tocar :=, <=, >=)
  r := regexp_replace(r, '([^<>!:=])=\s*''admin''' || c, '\1 IN (''admin''\3, ''superusuario''\3)', 'gi');
  -- IN ('admin', ...)   y   ARRAY['admin', ...]
  r := regexp_replace(r, '(\yin\s*\(\s*)''admin''' || c, '\1''admin''\3, ''superusuario''\3', 'gi');
  r := regexp_replace(r, '(array\s*\[\s*)''admin''' || c, '\1''admin''\3, ''superusuario''\3', 'gi');
  return r;
end $f$;

do $mig$
declare
  coltype text; roles text; cons record; fn record; po record; q text; w text; sql text; n int:=0;
begin
  select udt_name into coltype from information_schema.columns
   where table_schema='public' and table_name='profiles' and column_name='role';
  if coltype is null then raise exception 'No existe public.profiles.role'; end if;

  -- 1) permitir el valor nuevo
  if coltype not in ('text','varchar','bpchar') then
    if not exists (select 1 from pg_enum e join pg_type t on t.oid=e.enumtypid
                   where t.typname=coltype and e.enumlabel='superusuario') then
      raise exception 'profiles.role es un ENUM (%). Ejecuta primero SOLO esta línea y luego vuelve a correr este script:  alter type % add value ''superusuario'';', coltype, coltype;
    end if;
  else
    select string_agg(quote_literal(x), ',') into roles from (
      select distinct role::text x from public.profiles where role is not null
      union select 'admin' union select 'mesero' union select 'superusuario') s;
    for cons in select conname from pg_constraint
                where conrelid='public.profiles'::regclass and contype='c'
                  and pg_get_constraintdef(oid) ~* '\yrole\y' loop
      execute format('alter table public.profiles drop constraint %I', cons.conname);
    end loop;
    execute 'alter table public.profiles add constraint profiles_role_check check (role in ('||roles||'))';
  end if;

  -- 2a) funciones del esquema public que mencionan 'admin'
  for fn in
    select p.oid, p.proname, pg_get_functiondef(p.oid) def
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prokind='f'
      and not exists (select 1 from pg_depend d where d.objid=p.oid and d.deptype='e')
  loop
    if fn.def ~* '''admin''' and fn.def not like '%superusuario%' then
      sql := pg_temp.rw(fn.def);
      if sql <> fn.def then execute sql; n:=n+1; raise notice 'función reescrita: %', fn.proname; end if;
    end if;
  end loop;

  -- 2b) políticas RLS (public y storage)
  for po in select schemaname, tablename, policyname, qual, with_check from pg_policies
            where schemaname in ('public','storage') loop
    q := po.qual; w := po.with_check;
    if (coalesce(q,'')||coalesce(w,'')) ~* '''admin''' and (coalesce(q,'')||coalesce(w,'')) not like '%superusuario%' then
      sql := format('alter policy %I on %I.%I', po.policyname, po.schemaname, po.tablename);
      if q is not null then sql := sql || ' using ('||pg_temp.rw(q)||')'; end if;
      if w is not null then sql := sql || ' with check ('||pg_temp.rw(w)||')'; end if;
      begin execute sql; n:=n+1; raise notice 'política reescrita: %.%', po.tablename, po.policyname;
      exception when others then raise warning 'No se pudo reescribir % (%): %', po.policyname, po.tablename, sqlerrm; end;
    end if;
  end loop;
  raise notice 'Objetos reescritos: %', n;
end $mig$;

-- 3) Solo un superusuario puede dar o quitar el rol superusuario
create or replace function public.guard_superusuario() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (tg_op='INSERT' and new.role::text='superusuario')
     or (tg_op='UPDATE' and new.role::text is distinct from old.role::text
         and 'superusuario' in (new.role::text, old.role::text)) then
    if auth.uid() is not null
       and not exists (select 1 from public.profiles where id=auth.uid() and role::text='superusuario') then
      raise exception 'Solo un superusuario puede asignar o quitar ese nivel.';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists trg_guard_superusuario on public.profiles;
create trigger trg_guard_superusuario before insert or update of role on public.profiles
  for each row execute function public.guard_superusuario();

-- Revisión final: lo que todavía menciona 'admin' sin 'superusuario' (idealmente vacío)
select 'función' tipo, p.proname::text nombre
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.prokind='f' and pg_get_functiondef(p.oid) ~* '''admin'''
  and pg_get_functiondef(p.oid) not like '%superusuario%'
union all
select 'política', tablename||'.'||policyname from pg_policies
where schemaname in ('public','storage')
  and (coalesce(qual,'')||coalesce(with_check,'')) ~* '''admin'''
  and (coalesce(qual,'')||coalesce(with_check,'')) not like '%superusuario%';

-- ---------------------------------------------------------------------
-- Después: convierte a tu usuario en superusuario (cambia el nombre):
--   update public.profiles set role='superusuario' where username='TU_USUARIO';
-- ---------------------------------------------------------------------
