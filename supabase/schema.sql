CREATE TABLE public.audit_log (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  at timestamp with time zone DEFAULT now() NOT NULL,
  user_id uuid,
  username text,
  action text NOT NULL,
  CONSTRAINT audit_log_pkey PRIMARY KEY (id)
);

CREATE TABLE public.auto_close_day (
  day date NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT auto_close_day_pkey PRIMARY KEY (day)
);

CREATE TABLE public.expenses (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  amount numeric(10,2) NOT NULL,
  detail text NOT NULL,
  created_by uuid DEFAULT auth.uid(),
  created_at timestamp with time zone DEFAULT now(),
  shift_id bigint,
  CONSTRAINT expenses_pkey PRIMARY KEY (id)
);

CREATE TABLE public.openings (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  amount numeric(10,2) NOT NULL,
  note text,
  created_by uuid DEFAULT auth.uid(),
  created_at timestamp with time zone DEFAULT now(),
  shift_id bigint,
  CONSTRAINT openings_pkey PRIMARY KEY (id),
  CONSTRAINT openings_amount_check CHECK ((amount > (0)::numeric))
);

CREATE TABLE public.order_items (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  order_id bigint,
  product_id bigint,
  name text NOT NULL,
  price numeric(10,2) NOT NULL,
  qty integer NOT NULL,
  take_away boolean DEFAULT false,
  delivered boolean DEFAULT false,
  paid boolean DEFAULT false NOT NULL,
  handed boolean DEFAULT false NOT NULL,
  note text,
  CONSTRAINT order_items_pkey PRIMARY KEY (id),
  CONSTRAINT order_items_qty_check CHECK ((qty > 0))
);

CREATE TABLE public.orders (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  table_name text NOT NULL,
  paid boolean DEFAULT false,
  paid_at timestamp with time zone,
  created_by uuid DEFAULT auth.uid(),
  created_at timestamp with time zone DEFAULT now(),
  shift_id bigint,
  scheduled_for timestamp with time zone,
  CONSTRAINT orders_pkey PRIMARY KEY (id)
);

CREATE TABLE public.payment_proofs (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  payment_id bigint,
  order_id bigint,
  path text NOT NULL,
  created_by uuid DEFAULT auth.uid(),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT payment_proofs_pkey PRIMARY KEY (id)
);

CREATE TABLE public.payments (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  order_id bigint,
  person integer DEFAULT 1,
  method text,
  amount numeric(10,2),
  received numeric(10,2),
  change_given numeric(10,2),
  created_by uuid DEFAULT auth.uid(),
  created_at timestamp with time zone DEFAULT now(),
  shift_id bigint,
  CONSTRAINT payments_pkey PRIMARY KEY (id),
  CONSTRAINT payments_method_check CHECK ((method = ANY (ARRAY['efectivo'::text, 'transferencia'::text])))
);

CREATE TABLE public.products (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name text NOT NULL,
  price numeric(10,2) NOT NULL,
  category text DEFAULT 'General'::text,
  take_extra numeric(10,2) DEFAULT 0 NOT NULL,
  CONSTRAINT products_pkey PRIMARY KEY (id)
);

CREATE TABLE public.profiles (
  id uuid NOT NULL,
  username text NOT NULL,
  role text DEFAULT 'mesero'::text NOT NULL,
  blocked boolean DEFAULT false NOT NULL,
  CONSTRAINT profiles_username_key UNIQUE (username),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['superusuario'::text, 'mesero'::text, 'admin'::text])))
);

CREATE TABLE public.role_schedule (
  role text NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  tz text DEFAULT 'America/Guayaquil'::text NOT NULL,
  CONSTRAINT role_schedule_pkey PRIMARY KEY (role)
);

CREATE TABLE public.sessions_log (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid,
  username text,
  started_at timestamp with time zone DEFAULT now(),
  last_seen timestamp with time zone DEFAULT now(),
  ended_at timestamp with time zone,
  CONSTRAINT sessions_log_pkey PRIMARY KEY (id)
);

CREATE TABLE public.shifts (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  closed_at timestamp with time zone DEFAULT now(),
  closed_by uuid,
  total_cash numeric(10,2),
  total_transfer numeric(10,2),
  total_expenses numeric(10,2),
  auto boolean DEFAULT false NOT NULL,
  opening_cash numeric(10,2) DEFAULT 0 NOT NULL,
  CONSTRAINT shifts_pkey PRIMARY KEY (id)
);

CREATE TABLE public.staff (
  id uuid NOT NULL,
  full_name text,
  id_number text,
  phone text,
  contact_email text,
  address text,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT staff_pkey PRIMARY KEY (id)
);

ALTER TABLE public.expenses ADD CONSTRAINT expenses_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES shifts(id);

ALTER TABLE public.openings ADD CONSTRAINT openings_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES shifts(id);

ALTER TABLE public.order_items ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;

ALTER TABLE public.order_items ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL;

ALTER TABLE public.orders ADD CONSTRAINT orders_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES shifts(id);

ALTER TABLE public.payment_proofs ADD CONSTRAINT payment_proofs_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE SET NULL;

ALTER TABLE public.payments ADD CONSTRAINT payments_order_id_fkey FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;

ALTER TABLE public.payments ADD CONSTRAINT payments_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES shifts(id);

ALTER TABLE public.profiles ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.sessions_log ADD CONSTRAINT sessions_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE public.staff ADD CONSTRAINT staff_id_fkey FOREIGN KEY (id) REFERENCES profiles(id) ON DELETE CASCADE;

CREATE INDEX audit_log_at_idx ON public.audit_log USING btree (at DESC);

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.auto_close_day ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.openings ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.payment_proofs ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.role_schedule ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.sessions_log ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin ve eventos" ON public.audit_log AS PERMISSIVE FOR SELECT TO authenticated USING (is_admin());

CREATE POLICY "admin elimina retiros" ON public.expenses AS PERMISSIVE FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "cerrar jornada" ON public.expenses AS PERMISSIVE FOR UPDATE TO authenticated USING (is_active()) WITH CHECK (is_active());

CREATE POLICY "crear retiros" ON public.expenses AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (is_active());

CREATE POLICY "ver retiros" ON public.expenses AS PERMISSIVE FOR SELECT TO authenticated USING (is_active());

CREATE POLICY "admin elimina caja inicial" ON public.openings AS PERMISSIVE FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "cerrar jornada" ON public.openings AS PERMISSIVE FOR UPDATE TO authenticated USING (is_active()) WITH CHECK (is_active());

CREATE POLICY "crear caja inicial" ON public.openings AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (is_active());

CREATE POLICY "ver caja inicial" ON public.openings AS PERMISSIVE FOR SELECT TO authenticated USING (is_active());

CREATE POLICY operacion ON public.order_items AS PERMISSIVE FOR ALL TO authenticated USING (is_active()) WITH CHECK (is_active());

CREATE POLICY operacion ON public.orders AS PERMISSIVE FOR ALL TO authenticated USING (is_active()) WITH CHECK (is_active());

CREATE POLICY proofs_insert ON public.payment_proofs AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY proofs_select_admin ON public.payment_proofs AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::text, 'superusuario'::text, 'superusuario'::text]))))));

CREATE POLICY operacion ON public.payments AS PERMISSIVE FOR ALL TO authenticated USING (is_active()) WITH CHECK (is_active());

CREATE POLICY "solo admin escribe productos" ON public.products AS PERMISSIVE FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "ver productos" ON public.products AS PERMISSIVE FOR SELECT TO authenticated USING (is_active());

CREATE POLICY "admin gestiona perfiles" ON public.profiles AS PERMISSIVE FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "ver perfiles" ON public.profiles AS PERMISSIVE FOR SELECT TO authenticated USING (true);

CREATE POLICY "ver horarios" ON public.role_schedule AS PERMISSIVE FOR SELECT TO authenticated USING (true);

CREATE POLICY "admin ve sesiones" ON public.sessions_log AS PERMISSIVE FOR SELECT TO authenticated USING (is_admin());

CREATE POLICY operacion ON public.shifts AS PERMISSIVE FOR ALL TO authenticated USING (is_active()) WITH CHECK (is_active());

CREATE POLICY "datos propios o admin" ON public.staff AS PERMISSIVE FOR ALL TO authenticated USING ((is_active() AND ((id = auth.uid()) OR is_admin()))) WITH CHECK ((is_active() AND ((id = auth.uid()) OR is_admin())));

CREATE POLICY comprobantes_insert ON storage.objects AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((bucket_id = 'comprobantes'::text));

CREATE POLICY comprobantes_select_admin ON storage.objects AS PERMISSIVE FOR SELECT TO authenticated USING (((bucket_id = 'comprobantes'::text) AND (EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::text, 'superusuario'::text, 'superusuario'::text])))))));

CREATE OR REPLACE FUNCTION public.access_status()
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare p profiles; r role_schedule; t time;
begin
  select * into p from profiles where id=auth.uid();
  if not found then return 'deleted'; end if;
  if p.blocked then return 'blocked'; end if;
  select * into r from role_schedule where role=p.role;
  if found then
    t:=(now() at time zone r.tz)::time;
    if t<r.start_time or t>=r.end_time then
      return 'schedule '||to_char(r.start_time,'HH24:MI')||'-'||to_char(r.end_time,'HH24:MI');
    end if;
  end if;
  return 'ok';
end $function$
;

CREATE OR REPLACE FUNCTION public.admin_delete_user(uid uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not is_admin() then raise exception 'No autorizado'; end if;
  if uid=auth.uid() then raise exception 'No puedes eliminarte a ti mismo'; end if;
  delete from auth.users where id=uid; end $function$
;

CREATE OR REPLACE FUNCTION public.audit()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare d text; u text; n jsonb; o jsonb;
begin
  if tg_op<>'DELETE' then n:=to_jsonb(new); end if;
  if tg_op<>'INSERT' then o:=to_jsonb(old); end if;
  select username into u from profiles where id=auth.uid();

  if tg_table_name='orders' then
    if tg_op='INSERT' then d:=format('Creó el pedido #%s (%s)',n->>'id',n->>'table_name');
    elsif tg_op='DELETE' then d:=format('Eliminó el pedido #%s (%s)',o->>'id',o->>'table_name'); end if;

  elsif tg_table_name='order_items' then
    if tg_op='INSERT' then
      d:=format('Agregó %s× %s (%s) al pedido #%s',n->>'qty',n->>'name',case when (n->>'take_away')::boolean then 'para llevar' else 'para servir' end,n->>'order_id');
    elsif tg_op='UPDATE' then
      if n->>'qty' is distinct from o->>'qty' then
        d:=format('Cambió la cantidad de %s de %s a %s en el pedido #%s',n->>'name',o->>'qty',n->>'qty',n->>'order_id');
      elsif n->>'delivered' is distinct from o->>'delivered' then
        d:=format('%s: %s (pedido #%s)',case when (n->>'delivered')::boolean then 'Marcó como entregado' else 'Marcó como pendiente' end,n->>'name',n->>'order_id');
      end if;
    elsif tg_op='DELETE' then
      -- si se borró el pedido completo, ya queda registrado como "Eliminó el pedido"
      if exists(select 1 from orders where id=(o->>'order_id')::bigint) then
        d:=format('Quitó %s× %s del pedido #%s',o->>'qty',o->>'name',o->>'order_id'); end if;
    end if;

  elsif tg_table_name='products' then
    if tg_op='INSERT' then d:=format('Agregó el producto %s ($%s, recargo para llevar $%s)',n->>'name',n->>'price',n->>'take_extra');
    elsif tg_op='DELETE' then d:=format('Eliminó el producto %s',o->>'name');
    else d:=format('Editó el producto %s',o->>'name')
      ||case when n->>'name' is distinct from o->>'name' then format(' · nombre: %s → %s',o->>'name',n->>'name') else '' end
      ||case when n->>'price' is distinct from o->>'price' then format(' · precio: $%s → $%s',o->>'price',n->>'price') else '' end
      ||case when n->>'take_extra' is distinct from o->>'take_extra' then format(' · recargo para llevar: $%s → $%s',o->>'take_extra',n->>'take_extra') else '' end
      ||case when n->>'category' is distinct from o->>'category' then format(' · categoría: %s → %s',o->>'category',n->>'category') else '' end;
    end if;

  elsif tg_table_name='payments' then
    d:=format('Cobró $%s (%s) del pedido #%s',n->>'amount',n->>'method',n->>'order_id');

  elsif tg_table_name='expenses' then
    if tg_op='INSERT' then d:=format('Registró un retiro de caja de $%s: %s',n->>'amount',n->>'detail');
    elsif tg_op='DELETE' then d:=format('Eliminó el retiro de caja de $%s (%s)',o->>'amount',o->>'detail');
    elsif n->>'amount' is distinct from o->>'amount' or n->>'detail' is distinct from o->>'detail' then
      d:=format('Editó un retiro de caja: $%s (%s) → $%s (%s)',o->>'amount',o->>'detail',n->>'amount',n->>'detail'); end if;

  elsif tg_table_name='shifts' then
    d:=format('Terminó la jornada #%s (efectivo $%s, transferencia $%s, retiros $%s)',n->>'id',n->>'total_cash',n->>'total_transfer',n->>'total_expenses');

  elsif tg_table_name='profiles' then
    if tg_op='DELETE' then d:=format('Eliminó al usuario %s',o->>'username');
    elsif n->>'blocked' is distinct from o->>'blocked' then
      d:=format('%s al usuario %s',case when (n->>'blocked')::boolean then 'Bloqueó' else 'Habilitó' end,n->>'username');
    elsif n->>'role' is distinct from o->>'role' then
      d:=format('Cambió el nivel de %s: %s → %s',n->>'username',o->>'role',n->>'role'); end if;

  elsif tg_table_name='staff' then
    d:=format('Actualizó los datos personales de %s',(select username from profiles where id=(n->>'id')::uuid));
  end if;

  if d is not null then insert into audit_log(user_id,username,action) values(auth.uid(),coalesce(u,'sistema'),d); end if;
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.audit_handed()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.handed and not old.handed then
    insert into audit_log(user_id,username,action)
    values(auth.uid(),coalesce((select username from profiles where id=auth.uid()),'sistema'),
           format('Entregó al cliente: %s× %s (pedido #%s)',new.qty,new.name,new.order_id));
  end if;
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.audit_openings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare d text; u text;
begin
  select username into u from profiles where id=auth.uid();
  if tg_op='INSERT' then d:=format('Registró la caja inicial de $%s%s',new.amount,coalesce(' ('||new.note||')',''));
  elsif tg_op='DELETE' then d:=format('Eliminó un registro de caja inicial de $%s',old.amount);
  elsif new.amount is distinct from old.amount or new.note is distinct from old.note then
    d:=format('Editó la caja inicial: $%s → $%s',old.amount,new.amount);
  end if;
  if d is not null then insert into audit_log(user_id,username,action) values(auth.uid(),coalesce(u,'sistema'),d); end if;
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.auto_close_if_due()
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r role_schedule; n int;
begin
  select * into r from role_schedule where role='mesero';
  if not found then return null; end if;
  if (now() at time zone r.tz)::time < r.end_time then return null; end if;
  insert into auto_close_day(day) values((now() at time zone r.tz)::date) on conflict do nothing;
  get diagnostics n=row_count;
  if n=0 then return null; end if;
  return auto_close_shift();
end $function$
;

CREATE OR REPLACE FUNCTION public.auto_close_shift()
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare cash numeric; tr numeric; ex numeric; op numeric; sid bigint; ids bigint[]; np int; ne int; nop int;
begin
  perform pg_advisory_xact_lock(7);
  select coalesce(sum(amount) filter (where method='efectivo'),0),
         coalesce(sum(amount) filter (where method='transferencia'),0), count(*)
    into cash,tr,np from payments where shift_id is null;
  select coalesce(sum(amount),0), count(*) into ex,ne from expenses where shift_id is null;
  select coalesce(sum(amount),0), count(*) into op,nop from openings where shift_id is null;
  select array_agg(o.id) into ids from orders o
   where o.shift_id is null
     and exists(select 1 from order_items i where i.order_id=o.id)
     and not exists(select 1 from order_items i where i.order_id=o.id
                    and (not i.paid or not i.delivered or (i.take_away and not i.handed)));
  if np=0 and ne=0 and nop=0 and ids is null then return null; end if;
  insert into shifts(closed_by,total_cash,total_transfer,total_expenses,opening_cash,auto)
    values(auth.uid(),cash,tr,ex,op,true) returning id into sid;
  update payments set shift_id=sid where shift_id is null;
  update expenses set shift_id=sid where shift_id is null;
  update openings set shift_id=sid where shift_id is null;
  update orders set shift_id=sid where id=any(ids);
  insert into audit_log(user_id,username,action)
    values(auth.uid(),coalesce((select username from profiles where id=auth.uid()),'sistema'),
           format('La jornada #%s se cerró automáticamente por fin de horario',sid));
  return sid;
end $function$
;

CREATE OR REPLACE FUNCTION public.end_session(sid bigint)
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ update sessions_log set ended_at=now() where id=sid and user_id=auth.uid() $function$
;

CREATE OR REPLACE FUNCTION public.guard_expenses()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not is_admin() and (new.amount is distinct from old.amount or new.detail is distinct from old.detail) then
    raise exception 'Solo el administrador puede modificar retiros';
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.guard_openings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not is_admin() and (new.amount is distinct from old.amount or new.note is distinct from old.note) then
    raise exception 'Solo el administrador puede modificar la caja inicial';
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.guard_payment_total()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  tot  numeric;
  paid numeric;
begin
  -- bloquea el pedido para que dos cobros simultáneos se hagan uno tras otro
  perform 1 from public.orders where id = new.order_id for update;

  select coalesce(sum(qty * price), 0) into tot  from public.order_items where order_id = new.order_id;
  select coalesce(sum(amount), 0)      into paid from public.payments    where order_id = new.order_id;

  if paid + new.amount > tot + 0.005 then
    raise exception 'PAGO_DUPLICADO: este pedido ya está cobrado' using errcode = 'P0001';
  end if;
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.guard_superusuario()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin insert into profiles(id,username) values(new.id, split_part(new.email,'@',1)); return new; end $function$
;

CREATE OR REPLACE FUNCTION public.heartbeat(sid bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s text; r role_schedule;
begin
  update sessions_log set last_seen=now() where id=sid and user_id=auth.uid() and ended_at is null;
  s:=access_status();
  if s like 'schedule%' then perform auto_close_if_due(); end if;
  if s<>'ok' then return s; end if;
  select rs.* into r from role_schedule rs join profiles p on p.role=rs.role where p.id=auth.uid();
  if found then
    return 'ok:'||floor(extract(epoch from (r.end_time-(now() at time zone r.tz)::time)))::int;
  end if;
  return 'ok';
end $function$
;

CREATE OR REPLACE FUNCTION public.is_active()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ select access_status()='ok' $function$
;

CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ select exists(select 1 from profiles where id=auth.uid() and role IN ('admin', 'superusuario', 'superusuario') and not blocked) $function$
;

CREATE OR REPLACE FUNCTION public.log_event(p_action text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not is_admin() then raise exception 'No autorizado'; end if;
  insert into audit_log(user_id,username,action) select id,username,p_action from profiles where id=auth.uid();
end $function$
;

CREATE OR REPLACE FUNCTION public.start_session()
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare sid bigint; begin
  update sessions_log set ended_at=last_seen where user_id=auth.uid() and ended_at is null;
  insert into sessions_log(user_id,username) select id,username from profiles where id=auth.uid() returning id into sid;
  return sid; end $function$
;

CREATE TRIGGER audit_expenses AFTER INSERT OR DELETE OR UPDATE ON public.expenses FOR EACH ROW EXECUTE FUNCTION audit();

CREATE TRIGGER guard_expenses BEFORE UPDATE ON public.expenses FOR EACH ROW EXECUTE FUNCTION guard_expenses();

CREATE TRIGGER audit_openings AFTER INSERT OR DELETE OR UPDATE ON public.openings FOR EACH ROW EXECUTE FUNCTION audit_openings();

CREATE TRIGGER guard_openings BEFORE UPDATE ON public.openings FOR EACH ROW EXECUTE FUNCTION guard_openings();

CREATE TRIGGER audit_items AFTER INSERT OR DELETE OR UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION audit();

CREATE TRIGGER audit_items_handed AFTER UPDATE OF handed ON public.order_items FOR EACH ROW EXECUTE FUNCTION audit_handed();

CREATE TRIGGER audit_orders AFTER INSERT OR DELETE ON public.orders FOR EACH ROW EXECUTE FUNCTION audit();

CREATE TRIGGER audit_payments AFTER INSERT ON public.payments FOR EACH ROW EXECUTE FUNCTION audit();

CREATE TRIGGER trg_guard_payment BEFORE INSERT ON public.payments FOR EACH ROW EXECUTE FUNCTION guard_payment_total();

CREATE TRIGGER audit_products AFTER INSERT OR DELETE OR UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION audit();

CREATE TRIGGER audit_profiles AFTER DELETE OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION audit();

CREATE TRIGGER trg_guard_superusuario BEFORE INSERT OR UPDATE OF role ON public.profiles FOR EACH ROW EXECUTE FUNCTION guard_superusuario();

CREATE TRIGGER audit_shifts AFTER INSERT ON public.shifts FOR EACH ROW EXECUTE FUNCTION audit();

CREATE TRIGGER audit_staff AFTER INSERT OR UPDATE ON public.staff FOR EACH ROW EXECUTE FUNCTION audit();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES ('comprobantes', 'comprobantes', 'f', NULL, NULL) ON CONFLICT (id) DO NOTHING;