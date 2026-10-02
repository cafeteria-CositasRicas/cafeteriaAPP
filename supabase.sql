-- Ejecutar completo en Supabase > SQL Editor

create table profiles(id uuid primary key references auth.users on delete cascade, username text unique not null, role text not null default 'mesero');
create table products(id bigint generated always as identity primary key, name text not null, price numeric(10,2) not null, category text default 'General');
create table shifts(id bigint generated always as identity primary key, closed_at timestamptz default now(), closed_by uuid, total_cash numeric(10,2), total_transfer numeric(10,2), total_expenses numeric(10,2));
create table orders(id bigint generated always as identity primary key, table_name text not null, paid boolean default false, paid_at timestamptz, created_by uuid default auth.uid(), created_at timestamptz default now(), shift_id bigint references shifts);
create table order_items(id bigint generated always as identity primary key, order_id bigint references orders on delete cascade, product_id bigint references products on delete set null, name text not null, price numeric(10,2) not null, qty int not null check(qty>0), take_away boolean default false, delivered boolean default false);
create table payments(id bigint generated always as identity primary key, order_id bigint references orders on delete cascade, person int default 1, method text check(method in('efectivo','transferencia')), amount numeric(10,2), received numeric(10,2), change_given numeric(10,2), created_by uuid default auth.uid(), created_at timestamptz default now(), shift_id bigint references shifts);
create table expenses(id bigint generated always as identity primary key, amount numeric(10,2) not null, detail text not null, created_by uuid default auth.uid(), created_at timestamptz default now(), shift_id bigint references shifts);

-- Perfil automático al crear un usuario (rol inicial: mesero)
create function handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into profiles(id,username) values(new.id, split_part(new.email,'@',1)); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();

create function is_admin() returns boolean language sql security definer stable set search_path=public as
$$ select exists(select 1 from profiles where id=auth.uid() and role='admin') $$;

-- Seguridad (RLS)
alter table profiles enable row level security; alter table products enable row level security;
alter table orders enable row level security; alter table order_items enable row level security;
alter table payments enable row level security; alter table expenses enable row level security; alter table shifts enable row level security;

create policy "ver perfiles" on profiles for select to authenticated using(true);
create policy "admin gestiona perfiles" on profiles for all to authenticated using(is_admin()) with check(is_admin());
create policy "ver productos" on products for select to authenticated using(true);
create policy "solo admin escribe productos" on products for all to authenticated using(is_admin()) with check(is_admin());
create policy "operacion" on orders for all to authenticated using(true) with check(true);
create policy "operacion" on order_items for all to authenticated using(true) with check(true);
create policy "operacion" on payments for all to authenticated using(true) with check(true);
create policy "operacion" on expenses for all to authenticated using(true) with check(true);
create policy "operacion" on shifts for all to authenticated using(true) with check(true);

-- Tiempo real
alter publication supabase_realtime add table orders, order_items, payments, expenses, products;

-- Después de crear tu primer usuario (Authentication > Users, correo: admin@cafeteria.app):
-- update profiles set role='admin' where username='admin';
