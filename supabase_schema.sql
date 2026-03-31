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
DROP FUNCTION IF EXISTS public.recalculate_wallet_balance() CASCADE;


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
    tax_rate numeric, 
    tax_day int, 
    interest_rate numeric, 
    payout_schedule text, 
    payout_day int, 
    last_interest_payout timestamp with time zone,
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
    wallet_id uuid references wallets(id) on delete cascade not null,
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
    user_id uuid references auth.users(id) on delete cascade not null,
    book_id uuid references books(id) on delete cascade,
    from_wallet_id uuid references wallets(id) on delete cascade not null,
    to_wallet_id uuid references wallets(id) on delete cascade not null,
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
    wallet_id uuid references wallets(id) on delete cascade not null,
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
create policy "Users can manage their transfers" on transfer_transactions for all using (auth.uid() = user_id);

alter table recurring_transactions enable row level security;
create policy "Users can manage their recurring transactions" on recurring_transactions for all using (auth.uid() = user_id);

alter table assets_summary enable row level security;
create policy "Users can view their own assets summary" on assets_summary for select using (auth.uid() = user_id);

-- =========================================
-- 4. FUNCTIONS & TRIGGERS
-- =========================================

create or replace function set_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- Trigger to calculate wallet balance
CREATE OR REPLACE FUNCTION public.recalculate_wallet_balance()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    target_wallet_id uuid;
BEGIN
    IF TG_TABLE_NAME = 'transactions' THEN
        IF TG_OP = 'DELETE' THEN target_wallet_id := OLD.wallet_id;
        ELSE target_wallet_id := NEW.wallet_id; END IF;
    ELSIF TG_TABLE_NAME = 'transfer_transactions' THEN
        IF TG_OP = 'DELETE' THEN target_wallet_id := OLD.from_wallet_id;
        ELSE target_wallet_id := NEW.from_wallet_id; END IF;
    END IF;

    -- Update relevant wallets
    IF TG_TABLE_NAME = 'transactions' THEN
        UPDATE public.wallets
        SET balance = 
            COALESCE((SELECT SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) FROM public.transactions WHERE wallet_id = target_wallet_id AND deleted_at IS NULL), 0) +
            COALESCE((SELECT SUM(amount) FROM public.transfer_transactions WHERE to_wallet_id = target_wallet_id AND deleted_at IS NULL), 0) -
            COALESCE((SELECT SUM(amount) FROM public.transfer_transactions WHERE from_wallet_id = target_wallet_id AND deleted_at IS NULL), 0)
        WHERE id = target_wallet_id;
        
        IF TG_OP = 'UPDATE' AND OLD.wallet_id IS DISTINCT FROM NEW.wallet_id THEN
            UPDATE public.wallets
            SET balance = 
                COALESCE((SELECT SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) FROM public.transactions WHERE wallet_id = OLD.wallet_id AND deleted_at IS NULL), 0) +
                COALESCE((SELECT SUM(amount) FROM public.transfer_transactions WHERE to_wallet_id = OLD.wallet_id AND deleted_at IS NULL), 0) -
                COALESCE((SELECT SUM(amount) FROM public.transfer_transactions WHERE from_wallet_id = OLD.wallet_id AND deleted_at IS NULL), 0)
            WHERE id = OLD.wallet_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'transfer_transactions' THEN
        DECLARE
            w_from uuid := CASE WHEN TG_OP = 'DELETE' THEN OLD.from_wallet_id ELSE NEW.from_wallet_id END;
            w_to uuid := CASE WHEN TG_OP = 'DELETE' THEN OLD.to_wallet_id ELSE NEW.to_wallet_id END;
        BEGIN
            UPDATE public.wallets
            SET balance = 
                COALESCE((SELECT SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) FROM public.transactions WHERE wallet_id = w_from AND deleted_at IS NULL), 0) +
                COALESCE((SELECT SUM(amount) FROM public.transfer_transactions WHERE to_wallet_id = w_from AND deleted_at IS NULL), 0) -
                COALESCE((SELECT SUM(amount) FROM public.transfer_transactions WHERE from_wallet_id = w_from AND deleted_at IS NULL), 0)
            WHERE id = w_from;

            UPDATE public.wallets
            SET balance = 
                COALESCE((SELECT SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) FROM public.transactions WHERE wallet_id = w_to AND deleted_at IS NULL), 0) +
                COALESCE((SELECT SUM(amount) FROM public.transfer_transactions WHERE to_wallet_id = w_to AND deleted_at IS NULL), 0) -
                COALESCE((SELECT SUM(amount) FROM public.transfer_transactions WHERE from_wallet_id = w_to AND deleted_at IS NULL), 0)
            WHERE id = w_to;
        END;
    END IF;

    IF TG_OP = 'DELETE' THEN RETURN OLD;
    ELSE RETURN NEW; END IF;
END;
$$;

-- Apply updated_at to all tables
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

-- Apply wallet balance sync
create trigger sync_wallet_balance_on_transaction after insert or update or delete on transactions for each row execute procedure recalculate_wallet_balance();
create trigger sync_wallet_balance_on_transfer after insert or update or delete on transfer_transactions for each row execute procedure recalculate_wallet_balance();

-- =========================================
-- 5. INITIAL SETUP TRIGGER
-- =========================================

CREATE OR REPLACE FUNCTION public.handle_new_user_setup()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    default_book_id UUID;
    cat_id_expense UUID;
    cat_id_income UUID;
BEGIN
    -- 1. Setup User Settings & Summary
    INSERT INTO public.user_settings (user_id) VALUES (new.id);
    INSERT INTO public.assets_summary (user_id, total_balance) VALUES (new.id, 0);

    -- 2. Create Default Book & Wallet
    INSERT INTO public.books (user_id, name, icon) VALUES (new.id, 'Dompet Utama', '57409') 
    RETURNING id INTO default_book_id;
    
    INSERT INTO public.wallets (user_id, book_id, name, type, balance, icon) 
    VALUES (new.id, default_book_id, 'Tunai', 'cash', 0, '61263');

    -- 3. Create Default Expense Categories & Items
    -- Rekomendasi
    INSERT INTO public.categories (user_id, book_id, name, type, icon, color, is_default) 
    VALUES (new.id, default_book_id, 'Rekomendasi', 'expense', '58113', '0xFFFF9500', true) 
    RETURNING id INTO cat_id_expense;
    
    INSERT INTO public.category_items (category_id, name, icon) VALUES 
        (cat_id_expense, 'Diet', '57817'), (cat_id_expense, 'Harian', '57713'), 
        (cat_id_expense, 'Lalu Lintas', '57621'), (cat_id_expense, 'Sosial', '58349'),
        (cat_id_expense, 'Perumahan', '58136'), (cat_id_expense, 'Hadiah', '57635'),
        (cat_id_expense, 'Komunikasi', '58565'), (cat_id_expense, 'Pakaian', '57644'),
        (cat_id_expense, 'Rekreasi', '58127'), (cat_id_expense, 'Mempercantik', '57628'),
        (cat_id_expense, 'Medis', '58374'), (cat_id_expense, 'Pajak', '57580'),
        (cat_id_expense, 'Pendidikan', '58601'), (cat_id_expense, 'Bayi', '57604');

    -- Makan & Minum
    INSERT INTO public.categories (user_id, book_id, name, type, icon, color, is_default) 
    VALUES (new.id, default_book_id, 'Makan & Minum', 'expense', '57912', '0xFF448AFF', true) 
    RETURNING id INTO cat_id_expense;
    
    INSERT INTO public.category_items (category_id, name, icon) VALUES 
        (cat_id_expense, 'Makan', '57912'), (cat_id_expense, 'Minum', '57601'), (cat_id_expense, 'Jajan', '58356');

    -- Transportasi
    INSERT INTO public.categories (user_id, book_id, name, type, icon, color, is_default) 
    VALUES (new.id, default_book_id, 'Transportasi', 'expense', '58178', '0xFF448AFF', true) 
    RETURNING id INTO cat_id_expense;
    
    INSERT INTO public.category_items (category_id, name, icon) VALUES 
        (cat_id_expense, 'Bensin', '58178'), (cat_id_expense, 'Parkir', '58191'), (cat_id_expense, 'Ojek Online', '57405');

    -- Kebutuhan
    INSERT INTO public.categories (user_id, book_id, name, type, icon, color, is_default) 
    VALUES (new.id, default_book_id, 'Kebutuhan', 'expense', '57674', '0xFF448AFF', true) 
    RETURNING id INTO cat_id_expense;
    
    INSERT INTO public.category_items (category_id, name, icon) VALUES 
        (cat_id_expense, 'Listrik', '58330'), (cat_id_expense, 'Air', '58843'), (cat_id_expense, 'Internet', '58840');

    -- 4. Create Default Income Categories & Items
    -- Pendapatan
    INSERT INTO public.categories (user_id, book_id, name, type, icon, color, is_default) 
    VALUES (new.id, default_book_id, 'Pendapatan', 'income', '58509', '0xFF009688', true) 
    RETURNING id INTO cat_id_income;
    
    INSERT INTO public.category_items (category_id, name, icon) VALUES 
        (cat_id_income, 'Gaji', '58509'), (cat_id_income, 'Bonus', '58355'), (cat_id_income, 'Bunga', '58348');

    RETURN new;
END;
$$;

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user_setup();
