-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Create tables
create table wallets (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    name text not null,
    type text not null, -- 'ewallet', 'bank', 'cash'
    balance numeric not null default 0,
    icon text,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null,
    deleted_at timestamp with time zone
);

create table categories (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    name text not null,
    icon text,
    type text not null, -- 'income', 'expense'
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null,
    deleted_at timestamp with time zone
);

create table category_items (
    id uuid primary key default uuid_generate_v4(),
    category_id uuid references categories(id) on delete cascade not null,
    name text not null,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null,
    deleted_at timestamp with time zone
);

create table transactions (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    wallet_id uuid references wallets(id) not null,
    category_id uuid references categories(id) not null,
    amount numeric not null,
    type text not null, -- 'income', 'expense', 'transfer'
    note text,
    date timestamp with time zone not null,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null,
    deleted_at timestamp with time zone
);

create table transfer_transactions (
    id uuid primary key default uuid_generate_v4(),
    from_wallet_id uuid references wallets(id) not null,
    to_wallet_id uuid references wallets(id) not null,
    amount numeric not null,
    date timestamp with time zone not null,
    note text,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null,
    deleted_at timestamp with time zone
);

create table assets_summary (
    user_id uuid primary key references auth.users(id) on delete cascade not null,
    total_balance numeric not null default 0,
    updated_at timestamp with time zone default now() not null
);

-- 2. Setup Row Level Security (RLS)
-- Wallets
alter table wallets enable row level security;
create policy "Users can view their own wallets" on wallets for select using (auth.uid() = user_id);
create policy "Users can insert their own wallets" on wallets for insert with check (auth.uid() = user_id);
create policy "Users can update their own wallets" on wallets for update using (auth.uid() = user_id);

-- Categories
alter table categories enable row level security;
create policy "Users can view their own categories" on categories for select using (auth.uid() = user_id);
create policy "Users can insert their own categories" on categories for insert with check (auth.uid() = user_id);
create policy "Users can update their own categories" on categories for update using (auth.uid() = user_id);

-- Category Items
alter table category_items enable row level security;
create policy "Users can view category items of their categories" on category_items for select using (
    exists (select 1 from categories where categories.id = category_items.category_id and categories.user_id = auth.uid())
);
create policy "Users can manage category items of their categories" on category_items for all using (
    exists (select 1 from categories where categories.id = category_items.category_id and categories.user_id = auth.uid())
);

-- Transactions
alter table transactions enable row level security;
create policy "Users can view their own transactions" on transactions for select using (auth.uid() = user_id);
create policy "Users can insert their own transactions" on transactions for insert with check (auth.uid() = user_id);
create policy "Users can update their own transactions" on transactions for update using (auth.uid() = user_id);

-- Transfer Transactions
alter table transfer_transactions enable row level security;
create policy "Users can view their own transfers" on transfer_transactions for select using (
    exists (select 1 from wallets where wallets.id = transfer_transactions.from_wallet_id and wallets.user_id = auth.uid())
    or exists (select 1 from wallets where wallets.id = transfer_transactions.to_wallet_id and wallets.user_id = auth.uid())
);
create policy "Users can manage their own transfers" on transfer_transactions for all using (
    exists (select 1 from wallets where wallets.id = transfer_transactions.from_wallet_id and wallets.user_id = auth.uid())
);

-- Assets Summary
alter table assets_summary enable row level security;
create policy "Users can view their own assets summary" on assets_summary for select using (auth.uid() = user_id);

-- 3. Triggers for updated_at
create or replace function set_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger wallets_updated_at before update on wallets for each row execute procedure set_updated_at();
create trigger categories_updated_at before update on categories for each row execute procedure set_updated_at();
create trigger category_items_updated_at before update on category_items for each row execute procedure set_updated_at();
create trigger transactions_updated_at before update on transactions for each row execute procedure set_updated_at();
create trigger transfer_transactions_updated_at before update on transfer_transactions for each row execute procedure set_updated_at();
create trigger assets_summary_updated_at before update on assets_summary for each row execute procedure set_updated_at();
