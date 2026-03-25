-- =========================================
-- DATABASE RESET (DANGEROUS: RUN WITH CAUTION)
-- =========================================

DROP TABLE IF EXISTS public.transaction_attachments CASCADE;
DROP TABLE IF EXISTS public.transfer_transactions CASCADE;
DROP TABLE IF EXISTS public.transactions CASCADE;
DROP TABLE IF EXISTS public.category_items CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;
DROP TABLE IF EXISTS public.saving_goals CASCADE;
DROP TABLE IF EXISTS public.wallets CASCADE;
DROP TABLE IF EXISTS public.books CASCADE;
DROP TABLE IF EXISTS public.daily_summary CASCADE;
DROP TABLE IF EXISTS public.reminders CASCADE;
DROP TABLE IF EXISTS public.backups CASCADE;
DROP TABLE IF EXISTS public.user_settings CASCADE;
DROP TABLE IF EXISTS public.assets_summary CASCADE;
DROP TABLE IF EXISTS public.recurring_transactions CASCADE;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user_setup() CASCADE;
DROP FUNCTION IF EXISTS public.set_updated_at() CASCADE;


-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- =========================================
-- 1. FEATURE TABLES
-- =========================================

create table if not exists user_settings (
    user_id uuid primary key references auth.users(id) on delete cascade not null,
    biometric_enabled boolean default false not null,
    currency text default 'IDR' not null,
    theme text default 'light' not null,
    month_start_day int default 1 not null
);

create table if not exists backups (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    file_url text not null,
    backup_type text not null, -- 'google_drive', 'manual'
    created_at timestamp with time zone default now() not null
);

create table if not exists reminders (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    title text not null,
    description text,
    remind_at timestamp with time zone not null,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null
);

create table if not exists daily_summary (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    date date not null,
    total_income numeric not null default 0,
    total_expense numeric not null default 0,
    unique(user_id, date)
);

-- =========================================
-- 2. CORE FINANCE TABLES
-- =========================================

create table if not exists books (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    name text not null,
    icon text,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null
);

create table if not exists wallets (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    book_id uuid references books(id) on delete cascade,
    name text not null,
    type text not null, -- 'ewallet', 'bankmobile', 'digitalbank', 'cash'
    balance numeric not null default 0,
    icon text,
    -- New features for specific types
    tax_rate numeric, -- for bankmobile
    tax_day int, -- for bankmobile (day of month)
    interest_rate numeric, -- for digitalbank
    payout_schedule text, -- 'daily', 'monthly' for digitalbank
    payout_day int, -- for digitalbank monthly
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null,
    deleted_at timestamp with time zone
);

create table if not exists categories (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    book_id uuid references books(id) on delete cascade,
    name text not null,
    icon text,
    color text,
    is_default boolean default false,
    type text not null, -- 'income', 'expense'
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null,
    deleted_at timestamp with time zone
);

create table if not exists category_items (
    id uuid primary key default uuid_generate_v4(),
    category_id uuid references categories(id) on delete cascade not null,
    name text not null,
    icon text,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null,
    deleted_at timestamp with time zone
);

create table if not exists saving_goals (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    wallet_id uuid references wallets(id) on delete cascade,
    name text not null,
    target_amount numeric not null,
    current_amount numeric not null default 0,
    target_date date,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null
);

create table if not exists transactions (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    book_id uuid references books(id) on delete cascade,
    wallet_id uuid references wallets(id) not null,
    category_id uuid references categories(id) not null,
    category_item_id uuid references category_items(id),
    amount numeric not null,
    type text not null, -- 'income', 'expense', 'transfer'
    note text,
    date timestamp with time zone not null,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null,
    deleted_at timestamp with time zone
);

create table if not exists transaction_attachments (
    id uuid primary key default uuid_generate_v4(),
    transaction_id uuid references transactions(id) on delete cascade not null,
    image_url text not null,
    created_at timestamp with time zone default now() not null
);

create table if not exists transfer_transactions (
    id uuid primary key default uuid_generate_v4(),
    book_id uuid references books(id) on delete cascade,
    from_wallet_id uuid references wallets(id) not null,
    to_wallet_id uuid references wallets(id) not null,
    amount numeric not null,
    date timestamp with time zone not null,
    note text,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null,
    deleted_at timestamp with time zone
);

create table if not exists recurring_transactions (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    wallet_id uuid references wallets(id) not null,
    category_id uuid references categories(id) not null,
    amount numeric not null,
    type text not null,
    note text,
    frequency text not null, -- 'daily', 'weekly', 'monthly', 'yearly'
    next_run timestamp with time zone not null,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null
);

create table if not exists assets_summary (
    user_id uuid primary key references auth.users(id) on delete cascade not null,
    total_balance numeric not null default 0,
    updated_at timestamp with time zone default now() not null
);

-- =========================================
-- 3. ROW LEVEL SECURITY (RLS)
-- =========================================

alter table user_settings enable row level security;
create policy "Users can manage their settings" on user_settings for all using (auth.uid() = user_id);

alter table backups enable row level security;
create policy "Users can manage their backups" on backups for all using (auth.uid() = user_id);

alter table reminders enable row level security;
create policy "Users can manage their reminders" on reminders for all using (auth.uid() = user_id);

alter table daily_summary enable row level security;
create policy "Users can manage their daily summaries" on daily_summary for all using (auth.uid() = user_id);

alter table books enable row level security;
create policy "Users can manage their books" on books for all using (auth.uid() = user_id);

alter table wallets enable row level security;
create policy "Users can manage their wallets" on wallets for all using (auth.uid() = user_id);

alter table categories enable row level security;
create policy "Users can manage their categories" on categories for all using (auth.uid() = user_id);

alter table category_items enable row level security;
create policy "Users can view items of their categories" on category_items for select using (
    exists (select 1 from categories where categories.id = category_items.category_id and categories.user_id = auth.uid())
);
create policy "Users can manage items of their categories" on category_items for all using (
    exists (select 1 from categories where categories.id = category_items.category_id and categories.user_id = auth.uid())
);

alter table saving_goals enable row level security;
create policy "Users can manage their goals" on saving_goals for all using (auth.uid() = user_id);

alter table transactions enable row level security;
create policy "Users can manage their transactions" on transactions for all using (auth.uid() = user_id);

alter table transaction_attachments enable row level security;
create policy "Users can manage transaction attachments" on transaction_attachments for all using (
    exists (select 1 from transactions where transactions.id = transaction_attachments.transaction_id and transactions.user_id = auth.uid())
);

alter table transfer_transactions enable row level security;
create policy "Users can manage their transfers" on transfer_transactions for all using (
    exists (select 1 from wallets where wallets.id = transfer_transactions.from_wallet_id and wallets.user_id = auth.uid()) 
    or exists (select 1 from wallets where wallets.id = transfer_transactions.to_wallet_id and wallets.user_id = auth.uid())
);

alter table recurring_transactions enable row level security;
create policy "Users can manage their recurring transactions" on recurring_transactions for all using (auth.uid() = user_id);

alter table assets_summary enable row level security;
create policy "Users can view their own assets summary" on assets_summary for select using (auth.uid() = user_id);

-- =========================================
-- 4. TRIGGERS
-- =========================================

create or replace function set_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger reminders_updated_at before update on reminders for each row execute procedure set_updated_at();
create trigger books_updated_at before update on books for each row execute procedure set_updated_at();
create trigger wallets_updated_at before update on wallets for each row execute procedure set_updated_at();
create trigger categories_updated_at before update on categories for each row execute procedure set_updated_at();
create trigger category_items_updated_at before update on category_items for each row execute procedure set_updated_at();
create trigger saving_goals_updated_at before update on saving_goals for each row execute procedure set_updated_at();
create trigger transactions_updated_at before update on transactions for each row execute procedure set_updated_at();
create trigger transfer_transactions_updated_at before update on transfer_transactions for each row execute procedure set_updated_at();
create trigger recurring_transactions_updated_at before update on recurring_transactions for each row execute procedure set_updated_at();
create trigger assets_summary_updated_at before update on assets_summary for each row execute procedure set_updated_at();

-- =========================================
-- 5. INITIAL SETUP TRIGGER
-- =========================================

-- Function to handle new user setup (Dompet Utama + Tunai Wallet + Default Categories + Settings)
CREATE OR REPLACE FUNCTION public.handle_new_user_setup()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    default_book_id UUID;
    cat_campur_id UUID;
BEGIN
    -- 0. Create User Settings & Assets Summary
    INSERT INTO public.user_settings (user_id) VALUES (new.id);
    INSERT INTO public.assets_summary (user_id, total_balance) VALUES (new.id, 0);

    -- 1. Create Default Book (Dompet Utama)
    INSERT INTO public.books (user_id, name, icon)
    VALUES (new.id, 'Dompet Utama', '57409') -- Icons.account_balance_wallet
    RETURNING id INTO default_book_id;

    -- 2. Create Default Wallet (Tunai)
    INSERT INTO public.wallets (user_id, book_id, name, type, balance, icon)
    VALUES (new.id, default_book_id, 'Tunai', 'cash', 0, '61263'); -- Icons.money

    -- 3. Create "Campur" Category (Rekomendasi Expense)
    INSERT INTO public.categories (user_id, book_id, name, type, icon, color, is_default)
    VALUES (new.id, default_book_id, 'Campur', 'expense', '57674', '0xFF448AFF', true) -- Icons.category
    RETURNING id INTO cat_campur_id;

    -- 4. Create Category Items for "Campur"
    INSERT INTO public.category_items (category_id, name, icon)
    VALUES 
        (cat_campur_id, 'Bensin', '58178'), -- Icons.local_gas_station
        (cat_campur_id, 'Makan', '57912'), -- Icons.fastfood
        (cat_campur_id, 'Jajan', '58356'), -- Icons.icecream
        (cat_campur_id, 'Parkir', '58191'); -- Icons.local_parking

    -- 5. Create default income category
    INSERT INTO public.categories (user_id, book_id, name, type, icon, color, is_default)
    VALUES (new.id, default_book_id, 'Gaji', 'income', '58509', '0xFF009688', true); -- Icons.monetization_on

    RETURN new;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error details if needed or just return new to allow registration
        RETURN new;
END;
$$;

-- Cleanup existing trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger on auth.users (Must match Supabase Auth event)
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user_setup();

