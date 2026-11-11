-- My Men's Clothing Store: run this whole file once in Supabase > SQL Editor
create table public.products(id uuid primary key default gen_random_uuid(),name text not null,category text not null,price numeric(10,2) not null check(price>=0),old_price numeric(10,2),sizes text[] not null default '{S,M,L,XL,XXL}',image_url text,description text,created_at timestamptz not null default now());
create table public.orders(id uuid primary key default gen_random_uuid(),order_no bigint generated always as identity,name text not null,phone text not null,address text not null,items jsonb not null,total numeric(10,2) not null,status text not null default 'Pending' check(status in ('Pending','Confirmed','Shipped','Delivered')),created_at timestamptz not null default now());
create table public.admins(user_id uuid primary key references auth.users(id) on delete cascade);
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.admins where user_id=auth.uid()) $$;
alter table public.products enable row level security;alter table public.orders enable row level security;alter table public.admins enable row level security;
create policy products_read on public.products for select using(true);
create policy products_admin on public.products for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy orders_admin on public.orders for all to authenticated using(public.is_admin()) with check(public.is_admin());
-- Customers cannot touch orders directly; they call this function. Prices come from the database, never from the browser.
create or replace function public.place_order(p_name text,p_phone text,p_address text,p_items jsonb) returns bigint language plpgsql security definer set search_path=public as $$
declare v_total numeric:=0;v_items jsonb:='[]';r jsonb;p public.products;v_q int;v_no bigint;
begin
 if length(trim(p_name))<2 or length(trim(p_phone))<7 or length(trim(p_address))<5 then raise exception 'Invalid details';end if;
 if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 or jsonb_array_length(p_items)>50 then raise exception 'Invalid cart';end if;
 for r in select value from jsonb_array_elements(p_items) loop
  select * into p from public.products where id=(r->>'id')::uuid;
  if not found then raise exception 'Product not found';end if;
  v_q:=least(greatest(coalesce((r->>'q')::int,1),1),20);
  v_total:=v_total+p.price*v_q;
  v_items:=v_items||jsonb_build_array(jsonb_build_object('id',p.id,'name',p.name,'price',p.price,'size',left(coalesce(r->>'s',''),5),'q',v_q));
 end loop;
 insert into public.orders(name,phone,address,items,total) values(left(trim(p_name),100),left(trim(p_phone),30),left(trim(p_address),500),v_items,v_total) returning order_no into v_no;
 return v_no;
end $$;
revoke all on function public.place_order(text,text,text,jsonb) from public;
grant execute on function public.place_order(text,text,text,jsonb) to anon,authenticated;
-- Photo storage (public read, admin-only upload/delete)
insert into storage.buckets(id,name,public) values('product-images','product-images',true) on conflict do nothing;
create policy img_read on storage.objects for select using(bucket_id='product-images');
create policy img_ins on storage.objects for insert to authenticated with check(bucket_id='product-images' and public.is_admin());
create policy img_upd on storage.objects for update to authenticated using(bucket_id='product-images' and public.is_admin());
create policy img_del on storage.objects for delete to authenticated using(bucket_id='product-images' and public.is_admin());
-- AFTER creating your admin user in Authentication > Users, run this with YOUR email:
-- insert into public.admins(user_id) select id from auth.users where email='YOUR-EMAIL@example.com';
