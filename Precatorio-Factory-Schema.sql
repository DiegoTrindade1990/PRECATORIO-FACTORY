-- ============================================
-- PRECATÓRIO FACTORY - SCHEMA COMPLETO
-- Polícia Civil SP - Bonificação por Resultados
-- 100% LGPD Compliant - Dados fictícios para demo
-- ============================================

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- TABELA: ESCRITÓRIOS (Tenants)
create table public.escritorios (
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  cnpj text,
  email_responsavel text not null,
  telefone text,
  plano text not null default 'trial' check (plano in ('trial', 'starter', 'pro', 'enterprise')),
  status text not null default 'trial' check (status in ('trial', 'active', 'past_due', 'canceled')),
  max_policiais int not null default 3,
  policiais_usados_mes int not null default 0,
  mes_referencia date not null default date_trunc('month', now()),
  asaas_customer_id text,
  created_at timestamptz default now(),
  trial_ends_at timestamptz default now() + interval '7 days'
);

-- TABELA: USUÁRIOS
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  escritorio_id uuid references public.escritorios(id) on delete cascade,
  nome text,
  email text,
  cargo text default 'advogado',
  created_at timestamptz default now()
);

-- TABELA: ASSINATURAS
create table public.assinaturas (
  id uuid primary key default uuid_generate_v4(),
  escritorio_id uuid references public.escritorios(id) on delete cascade not null,
  plano text not null,
  status text not null,
  valor numeric(10,2) not null,
  ciclo text default 'monthly',
  asaas_subscription_id text,
  current_period_start timestamptz,
  current_period_end timestamptz,
  created_at timestamptz default now()
);

-- TABELA: POLICIAIS (Fictícios)
create table public.policiais (
  id uuid primary key default uuid_generate_v4(),
  escritorio_id uuid references public.escritorios(id) on delete cascade not null,
  nome_completo text not null,
  nome_ficticio boolean default true,
  matricula_mask text,
  cargo text,
  status text default 'analisando' check (status in ('analisando', 'pronto', 'falta_docs')),
  total_teses numeric(12,2) default 0,
  created_at timestamptz default now()
);

-- TABELA: DOCUMENTOS (Holerites)
create table public.documentos (
  id uuid primary key default uuid_generate_v4(),
  policial_id uuid references public.policiais(id) on delete cascade not null,
  escritorio_id uuid references public.escritorios(id) on delete cascade not null,
  ano int not null,
  mes int,
  nome_arquivo_original text,
  tipo text default 'holerite_fazenda_sp',
  bonus_extraido numeric(10,2),
  retp_extraido numeric(10,2),
  salario_base_extraido numeric(10,2),
  status_extracao text default 'extraido' check (status_extracao in ('pendente', 'extraido', 'erro')),
  auto_delete_at timestamptz default now() + interval '24 hours',
  created_at timestamptz default now()
);

-- TABELA: CÁLCULOS
create table public.calculos (
  id uuid primary key default uuid_generate_v4(),
  policial_id uuid references public.policiais(id) on delete cascade not null,
  escritorio_id uuid references public.escritorios(id) on delete cascade not null,
  ano int not null,
  tese text not null check (tese in ('BR', 'SEXTA_PARTE', 'QUINQUENIO', 'ALE', 'PANDEMIA')),
  bonus_anual numeric(10,2),
  valor_13 numeric(10,2),
  valor_ferias numeric(10,2),
  valor_terco numeric(10,2),
  valor_licenca numeric(10,2),
  total_sem_correcao numeric(12,2),
  total_com_correcao numeric(12,2),
  indice_correcao text default 'IPCA-E + Juros 0,5% a.m.',
  created_at timestamptz default now(),
  unique(policial_id, ano, tese)
);

-- TABELA: PAGAMENTOS (Asaas)
create table public.pagamentos (
  id uuid primary key default uuid_generate_v4(),
  escritorio_id uuid references public.escritorios(id) on delete cascade not null,
  asaas_payment_id text unique,
  valor numeric(10,2),
  status text check (status in ('PENDING', 'RECEIVED', 'CONFIRMED', 'OVERDUE', 'REFUNDED')),
  forma text,
  data_vencimento date,
  data_pagamento timestamptz,
  link_boleto text,
  qr_code_pix text,
  created_at timestamptz default now()
);

-- TABELA: LOGS LGPD
create table public.logs_acesso (
  id uuid primary key default uuid_generate_v4(),
  escritorio_id uuid references public.escritorios(id),
  user_id uuid references public.profiles(id),
  acao text,
  policial_id uuid,
  ip text,
  created_at timestamptz default now()
);

-- RLS
alter table public.escritorios enable row level security;
alter table public.profiles enable row level security;
alter table public.policiais enable row level security;
alter table public.documentos enable row level security;
alter table public.calculos enable row level security;
alter table public.pagamentos enable row level security;
alter table public.assinaturas enable row level security;
alter table public.logs_acesso enable row level security;

create policy "Usuario ve seu escritorio" on public.escritorios for all using (
  id in (select escritorio_id from public.profiles where id = auth.uid())
);

create policy "Profiles mesmo escritorio" on public.profiles for all using (
  escritorio_id in (select escritorio_id from public.profiles where id = auth.uid())
);

create policy "Policiais do escritorio" on public.policiais for all using (
  escritorio_id in (select escritorio_id from public.profiles where id = auth.uid())
);

create policy "Documentos do escritorio" on public.documentos for all using (
  escritorio_id in (select escritorio_id from public.profiles where id = auth.uid())
);

create policy "Calculos do escritorio" on public.calculos for all using (
  escritorio_id in (select escritorio_id from public.profiles where id = auth.uid())
);

-- Função reset mensal
create or replace function public.reset_contador_mensal() returns void as $$
begin
  update public.escritorios set policiais_usados_mes = 0, mes_referencia = date_trunc('month', now()) where mes_referencia < date_trunc('month', now());
end;
$$ language plpgsql;

-- Função limite
create or replace function public.check_limite_policiais() returns trigger as $$
declare max_limite int; usados int; status_escritorio text;
begin
  select max_policiais, policiais_usados_mes, status into max_limite, usados, status_escritorio from public.escritorios where id = NEW.escritorio_id;
  if status_escritorio = 'past_due' or status_escritorio = 'canceled' then raise exception 'Assinatura inativa. Regularize.';
  end if;
  if usados >= max_limite and TG_OP = 'INSERT' then raise exception 'Limite atingido. Upgrade.';
  end if;
  return NEW;
end;
$$ language plpgsql;

create trigger trg_check_limite before insert on public.policiais for each row execute function public.check_limite_policiais();

-- SEED FICTÍCIO
insert into public.escritorios (id, nome, email_responsavel, plano, status, max_policiais, policiais_usados_mes) values
('11111111-1111-1111-1111-111111111111', 'Escritório Demo Fartura', 'demo@fartura.adv.br', 'pro', 'active', 999999, 3),
('22222222-2222-2222-2222-222222222222', 'Silva & Associados - Trial', 'silva@adv.br', 'trial', 'trial', 3, 3);

insert into public.policiais (escritorio_id, nome_completo, matricula_mask, cargo, status, total_teses) values
('11111111-1111-1111-1111-111111111111', 'JOÃO SILVA (Fictício)', '123***', 'Delegado 3ª Classe', 'pronto', 18450.00),
('11111111-1111-1111-1111-111111111111', 'MARIA SANTOS (Fictícia)', '456***', 'Investigadora', 'falta_docs', 12320.00),
('11111111-1111-1111-1111-111111111111', 'CARLOS OLIVEIRA (Fictício)', '789***', 'Escrivão', 'pronto', 17122.00);
