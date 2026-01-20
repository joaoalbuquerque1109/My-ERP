create extension if not exists "pgcrypto";

create table tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  tenant_profile text not null check (tenant_profile in ('PRIVATE', 'PUBLIC')),
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table tenant_profiles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code in ('PRIVATE', 'PUBLIC')),
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table users (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  auth_user_id uuid not null,
  full_name text not null,
  email text not null,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid
);

create table roles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  name text not null,
  scope text not null default 'tenant',
  created_at timestamptz not null default now(),
  created_by uuid
);

create table permissions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  description text,
  module text not null,
  created_at timestamptz not null default now()
);

create table role_permissions (
  role_id uuid not null references roles(id),
  permission_id uuid not null references permissions(id),
  created_at timestamptz not null default now(),
  created_by uuid,
  primary key (role_id, permission_id)
);

create table user_roles (
  user_id uuid not null references users(id),
  role_id uuid not null references roles(id),
  created_at timestamptz not null default now(),
  created_by uuid,
  primary key (user_id, role_id)
);

create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  user_id uuid references users(id),
  action text not null,
  entity text not null,
  entity_id uuid,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  hash text not null
);

create table documents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  module text not null,
  entity text not null,
  entity_id uuid not null,
  file_path text not null,
  mime_type text not null,
  version int not null default 1,
  created_at timestamptz not null default now(),
  created_by uuid
);

create table workflows (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  name text not null,
  profile text not null check (profile in ('PRIVATE', 'PUBLIC')),
  entity text not null,
  created_at timestamptz not null default now(),
  created_by uuid
);

create table workflow_steps (
  id uuid primary key default gen_random_uuid(),
  workflow_id uuid not null references workflows(id),
  step_order int not null,
  name text not null,
  required_role_id uuid references roles(id),
  allowed_transitions jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid
);

create table clients (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  name text not null,
  document_number text not null,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid
);

create table contracts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  client_id uuid not null references clients(id),
  start_date date not null,
  end_date date,
  value numeric(14, 2) not null,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  created_by uuid
);

create table invoices (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  client_id uuid not null references clients(id),
  issue_date date not null,
  due_date date not null,
  amount numeric(14, 2) not null,
  status text not null default 'draft',
  created_at timestamptz not null default now(),
  created_by uuid
);

create table accounts_receivable (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  invoice_id uuid not null references invoices(id),
  amount numeric(14, 2) not null,
  due_date date not null,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  created_by uuid
);

create table accounts_payable (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  supplier_name text not null,
  document_number text not null,
  amount numeric(14, 2) not null,
  due_date date not null,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  created_by uuid
);

create table employees (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  person_name text not null,
  cpf text not null,
  pis_pasep text,
  birth_date date not null,
  hire_date date not null,
  termination_date date,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid
);

create table employment_contracts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  employee_id uuid not null references employees(id),
  contract_type text not null check (contract_type in ('CLT', 'ESTATUTARIO', 'TEMPORARIO')),
  job_title text not null,
  workload_hours numeric(5, 2) not null,
  salary_base numeric(14, 2) not null,
  collective_agreement_code text,
  start_date date not null,
  end_date date,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  created_by uuid
);

create table payrolls (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  reference_month int not null check (reference_month between 1 and 12),
  reference_year int not null,
  status text not null default 'draft',
  created_at timestamptz not null default now(),
  created_by uuid
);

create table payslips (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  payroll_id uuid not null references payrolls(id),
  employee_id uuid not null references employees(id),
  gross_amount numeric(14, 2) not null,
  discounts_amount numeric(14, 2) not null,
  net_amount numeric(14, 2) not null,
  issued_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid
);

create table benefits (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  code text not null,
  name text not null,
  benefit_type text not null,
  calculation_rule jsonb not null,
  created_at timestamptz not null default now(),
  created_by uuid
);

create table benefit_enrollments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  employee_id uuid not null references employees(id),
  benefit_id uuid not null references benefits(id),
  start_date date not null,
  end_date date,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  created_by uuid
);

create table absences (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  employee_id uuid not null references employees(id),
  absence_type text not null,
  start_date date not null,
  end_date date not null,
  legal_basis text,
  status text not null default 'reported',
  created_at timestamptz not null default now(),
  created_by uuid
);

create table budget_units (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  code text not null,
  name text not null,
  fiscal_year int not null,
  created_at timestamptz not null default now(),
  created_by uuid
);

create table budget_allocations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  budget_unit_id uuid not null references budget_units(id),
  program_code text not null,
  action_code text not null,
  amount numeric(16, 2) not null,
  created_at timestamptz not null default now(),
  created_by uuid
);

create table commitments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  budget_allocation_id uuid not null references budget_allocations(id),
  commitment_number text not null,
  amount numeric(16, 2) not null,
  status text not null default 'pre_empenho',
  created_at timestamptz not null default now(),
  created_by uuid
);

create table liquidations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  commitment_id uuid not null references commitments(id),
  liquidation_number text not null,
  amount numeric(16, 2) not null,
  status text not null default 'em_analise',
  created_at timestamptz not null default now(),
  created_by uuid
);

create table payments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  liquidation_id uuid not null references liquidations(id),
  payment_number text not null,
  amount numeric(16, 2) not null,
  status text not null default 'programado',
  created_at timestamptz not null default now(),
  created_by uuid
);

create table public_contracts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id),
  contract_number text not null,
  supplier_name text not null,
  amount numeric(16, 2) not null,
  start_date date not null,
  end_date date,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  created_by uuid
);

alter table tenants enable row level security;
alter table users enable row level security;
alter table roles enable row level security;
alter table user_roles enable row level security;
alter table permissions enable row level security;
alter table role_permissions enable row level security;
alter table audit_logs enable row level security;
alter table documents enable row level security;
alter table workflows enable row level security;
alter table workflow_steps enable row level security;
alter table clients enable row level security;
alter table contracts enable row level security;
alter table invoices enable row level security;
alter table accounts_receivable enable row level security;
alter table accounts_payable enable row level security;
alter table employees enable row level security;
alter table employment_contracts enable row level security;
alter table payrolls enable row level security;
alter table payslips enable row level security;
alter table benefits enable row level security;
alter table benefit_enrollments enable row level security;
alter table absences enable row level security;
alter table budget_units enable row level security;
alter table budget_allocations enable row level security;
alter table commitments enable row level security;
alter table liquidations enable row level security;
alter table payments enable row level security;
alter table public_contracts enable row level security;

create policy tenant_isolation on tenants
  for select using (id::text = auth.jwt() ->> 'tenant_id');

create policy tenant_isolation_users on users
  using (tenant_id::text = auth.jwt() ->> 'tenant_id');

create policy tenant_isolation_generic on documents
  using (tenant_id::text = auth.jwt() ->> 'tenant_id');
