-- ============================================
-- PRECATÓRIO FACTORY V6 - SCHEMA COMPLETO ONLINE
-- Baseado no OrganizadorPDFv5.py + Novas features
-- ============================================

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ESCRITÓRIOS (Tenants)
create table public.escritorios (
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  cnpj text,
  email_responsavel text not null,
  telefone text,
  plano text not null default 'trial' check (plano in ('trial', 'starter', 'pro', 'enterprise')),
  status text not null default 'trial' check (status in ('trial', 'active', 'past_due', 'canceled')),
  max_policiais int not null default 3,
  max_processamentos_mes int not null default 10,
  processamentos_usados_mes int not null default 0,
  policiais_usados_mes int not null default 0,
  mes_referencia date not null default date_trunc('month', now()),
  asaas_customer_id text,
  google_drive_connected boolean default false,
  created_at timestamptz default now(),
  trial_ends_at timestamptz default now() + interval '7 days'
);

-- PROFILES
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  escritorio_id uuid references public.escritorios(id) on delete cascade,
  nome text,
  email text,
  cargo text default 'advogado',
  is_admin boolean default false,
  created_at timestamptz default now()
);

-- TIPOS DE CÁLCULO SUPORTADOS (do OrganizadorPDFv5)
create table public.tipos_calculo (
  codigo text primary key, -- GAT, IR_ALIMENTACAO, BR, etc
  nome text not null,
  descricao text,
  codigo_rubrica text not null, -- 04.153, 12.080, etc
  template_excel_nome text,
  ativo boolean default true
);

insert into public.tipos_calculo (codigo, nome, descricao, codigo_rubrica) values
('GAT', 'GAT - Grat. Acúmulo Titularidade', 'Inclusão da GAT na base de 13º, férias, 1/3 e licença-prêmio - Código 04.153', '04.153'),
('IR_ALIMENTACAO', 'IRRF - Ajuda Custo Alimentação', 'IRRF com exclusão de ajuda custo alimentação e auxílio transporte - Código 12.080', '12.080'),
('BR', 'Bonificação por Resultados', 'BR sobre 13º, férias, 1/3 e licença - Bônus anual', 'BR'),
('SEXTA_PARTE', 'Sexta-Parte e Quinquênio', 'Sexta-parte e quinquênio sobre RETP, GAT, ALE, Insalubridade', '09.001');

-- POLICIAIS / SERVIDORES
create table public.servidores (
  id uuid primary key default uuid_generate_v4(),
  escritorio_id uuid references public.escritorios(id) on delete cascade not null,
  nome_completo text not null,
  nome_ficticio boolean default false,
  matricula_mask text,
  cargo text,
  status text default 'analisando',
  total_teses numeric(12,2) default 0,
  created_at timestamptz default now()
);

-- JOBS DE PROCESSAMENTO (Fila)
create table public.jobs (
  id uuid primary key default uuid_generate_v4(),
  escritorio_id uuid references public.escritorios(id) on delete cascade not null,
  servidor_id uuid references public.servidores(id) on delete set null,
  tipo_calculo text references public.tipos_calculo(codigo) not null,
  status text not null default 'queued' check (status in ('queued', 'processing', 'completed', 'failed')),
  origem text not null check (origem in ('upload_pdf', 'upload_zip', 'gdrive_link', 'onedrive_link')),
  gdrive_url text,
  arquivo_nome_original text,
  arquivo_tamanho bigint,
  total_paginas int,
  paginas_processadas int default 0,
  erro_mensagem text,
  resultado_arquivo_url text,
  created_at timestamptz default now(),
  completed_at timestamptz
);

-- DOCUMENTOS EXTRAÍDOS (temporário - auto-delete)
create table public.documentos_extraidos (
  id uuid primary key default uuid_generate_v4(),
  job_id uuid references public.jobs(id) on delete cascade not null,
  escritorio_id uuid references public.escritorios(id) on delete cascade not null,
  ano int not null,
  mes int not null,
  tipo_folha text,
  rubrica_codigo text,
  rubrica_descricao text,
  valor_extraido numeric(12,2),
  data_referencia date,
  auto_delete_at timestamptz default now() + interval '24 hours',
  created_at timestamptz default now()
);

-- CÁLCULOS RESULTANTES
create table public.calculos (
  id uuid primary key default uuid_generate_v4(),
  servidor_id uuid references public.servidores(id) on delete cascade not null,
  escritorio_id uuid references public.escritorios(id) on delete cascade not null,
  job_id uuid references public.jobs(id) on delete set null,
  ano int not null,
  mes int not null,
  tipo_calculo text references public.tipos_calculo(codigo) not null,
  valor_rubrica numeric(12,2),
  valor_13 numeric(12,2),
  valor_ferias numeric(12,2),
  valor_terco numeric(12,2),
  valor_licenca numeric(12,2),
  total_sem_correcao numeric(12,2),
  total_com_correcao numeric(12,2),
  created_at timestamptz default now()
);

-- LOGS DE ERRO DO SISTEMA (NÃO armazena dados de clientes, só metadados)
create table public.logs_sistema (
  id uuid primary key default uuid_generate_v4(),
  escritorio_id uuid references public.escritorios(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  nivel text check (nivel in ('info', 'warning', 'error', 'critical')),
  origem text, -- pdfplumber, openpyxl, gdrive, zip, etc
  mensagem text not null,
  stack_trace text,
  arquivo_nome text,
  tempo_processamento_ms int,
  created_at timestamptz default now()
);

-- RELATÓRIOS ADMIN (Para você ver)
create table public.relatorios_admin (
  id uuid primary key default uuid_generate_v4(),
  data_ref date default current_date,
  total_escritorios_ativos int,
  total_jobs_processados int,
  total_jobs_falhados int,
  total_receita_dia numeric(12,2),
  tempo_medio_processamento_ms int,
  erros_mais_comuns jsonb,
  created_at timestamptz default now()
);

-- PAGAMENTOS ASAAS
create table public.pagamentos (
  id uuid primary key default uuid_generate_v4(),
  escritorio_id uuid references public.escritorios(id) on delete cascade not null,
  asaas_payment_id text unique,
  valor numeric(10,2),
  status text check (status in ('PENDING', 'RECEIVED', 'CONFIRMED', 'OVERDUE', 'REFUNDED')),
  forma text,
  data_vencimento date,
  data_pagamento timestamptz,
  created_at timestamptz default now()
);

-- ASSINATURAS
create table public.assinaturas (
  id uuid primary key default uuid_generate_v4(),
  escritorio_id uuid references public.escritorios(id) on delete cascade not null,
  plano text not null,
  status text not null,
  valor numeric(10,2) not null,
  asaas_subscription_id text,
  current_period_end timestamptz,
  created_at timestamptz default now()
);

-- RLS
alter table public.escritorios enable row level security;
alter table public.profiles enable row level security;
alter table public.servidores enable row level security;
alter table public.jobs enable row level security;
alter table public.documentos_extraidos enable row level security;
alter table public.calculos enable row level security;
alter table public.logs_sistema enable row level security;
alter table public.pagamentos enable row level security;

-- Políticas: usuário só vê seu escritório, mas admin vê tudo
create policy "Escritorio do usuario" on public.escritorios for all using (
  id in (select escritorio_id from public.profiles where id = auth.uid()) 
  OR exists (select 1 from public.profiles where id = auth.uid() and is_admin = true)
);

create policy "Servidores do escritorio" on public.servidores for all using (
  escritorio_id in (select escritorio_id from public.profiles where id = auth.uid()) 
  OR exists (select 1 from public.profiles where id = auth.uid() and is_admin = true)
);

create policy "Jobs do escritorio" on public.jobs for all using (
  escritorio_id in (select escritorio_id from public.profiles where id = auth.uid())
  OR exists (select 1 from public.profiles where id = auth.uid() and is_admin = true)
);

-- Função para log de erro (não guarda dados sensíveis)
create or replace function public.log_erro(
  p_escritorio_id uuid,
  p_job_id uuid,
  p_nivel text,
  p_origem text,
  p_mensagem text,
  p_arquivo_nome text default null
) returns void as $$
begin
  insert into public.logs_sistema (escritorio_id, job_id, nivel, origem, mensagem, arquivo_nome)
  values (p_escritorio_id, p_job_id, p_nivel, p_origem, p_mensagem, p_arquivo_nome);
end;
$$ language plpgsql;

-- Seed tipos
-- Já inserido acima
