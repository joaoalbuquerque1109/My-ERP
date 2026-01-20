# ERP Híbrido Multi-Tenant (PRIVATE/PUBLIC) — Arquitetura e Modelo

## 1. Arquitetura geral

### Visão macro
- **Frontend (Next.js App Router + TypeScript)**: camada de UI e orquestração de fluxos por perfil de tenant, com rotas protegidas, layouts dinâmicos e componentes reutilizáveis.
- **Backend (Supabase)**:
  - **PostgreSQL**: banco multi-tenant com RLS para isolamento total.
  - **Auth**: autenticação centralizada (JWT) integrada com `tenants`, `users` e `roles`.
  - **Storage**: documentos e anexos versionados, com políticas por tenant.
  - **Edge Functions**: validações complexas, integrações e ações transacionais sensíveis.

### Multi-tenant no Supabase
1. **Isolamento por tenant_id**: todas as tabelas de negócio possuem `tenant_id`.
2. **RLS com claims do JWT**:
   - O JWT traz `tenant_id`, `user_id` e `role_ids` como claims.
   - Políticas de RLS comparam `tenant_id` da linha com o claim.
3. **Catálogo de módulos por tenant_profile**:
   - `tenant_profile` controla módulos visíveis, regras e vocabulário.
4. **Segurança por padrão**:
   - Todas as tabelas com RLS habilitado e políticas explícitas.

### Controle por tenant_profile (PUBLIC/PRIVATE)
- **Módulos visíveis**: tabela de configuração (ex.: `tenant_modules`) filtra módulos expostos no frontend.
- **Regras de validação**:
  - Validações críticas em **Edge Functions** e **triggers**.
  - Ex.: regras orçamentárias no setor público.
- **Fluxos de aprovação**:
  - `workflows` + `workflow_steps` variam por perfil.
- **Vocabulário**:
  - Dicionário por tenant_profile (ex.: “cliente” vs “fornecedor”, “empenho” vs “pedido”).

---

## 2. Modelagem de banco de dados (PostgreSQL)

### Núcleo comum

#### `tenants`
- **Campos**: `id (pk)`, `name`, `tenant_profile (PUBLIC/PRIVATE)`, `status`, `created_at`, `updated_at`.
- **Relacionamentos**: 1:N com `users`, `documents`, `workflows`, módulos.
- **Auditoria**: `created_at`, `updated_at`.

#### `tenant_profiles`
- **Campos**: `id (pk)`, `code (PUBLIC/PRIVATE)`, `name`, `description`.
- **Relacionamentos**: 1:N com `tenants`.
- **Auditoria**: `created_at`, `updated_at`.

#### `users`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `auth_user_id (uuid do Supabase Auth)`, `full_name`, `email`, `status`, `created_at`, `updated_at`.
- **Relacionamentos**: N:M com `roles` via `user_roles`.
- **Auditoria**: `created_at`, `updated_at`, `created_by`.

#### `roles`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `name`, `scope (system/tenant)`, `created_at`.
- **Relacionamentos**: N:M com `permissions` via `role_permissions`.
- **Auditoria**: `created_at`, `created_by`.

#### `permissions`
- **Campos**: `id (pk)`, `code`, `description`, `module`, `created_at`.
- **Relacionamentos**: N:M com `roles`.
- **Auditoria**: `created_at`.

#### `user_roles`
- **Campos**: `user_id (fk)`, `role_id (fk)`, `created_at`.
- **Relacionamentos**: liga usuários a papéis.
- **Auditoria**: `created_at`, `created_by`.

#### `audit_logs`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `user_id (fk)`, `action`, `entity`, `entity_id`, `payload (jsonb)`, `created_at`, `hash`.
- **Relacionamentos**: N:1 com `tenants`, `users`.
- **Auditoria**: **imutável** por design.

#### `documents`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `module`, `entity`, `entity_id`, `file_path`, `mime_type`, `version`, `created_at`, `created_by`.
- **Relacionamentos**: N:1 com `tenants`, entidades de negócio.
- **Auditoria**: `created_at`, `created_by`.

#### `workflows`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `name`, `profile (PUBLIC/PRIVATE)`, `entity`, `created_at`.
- **Relacionamentos**: 1:N com `workflow_steps`.
- **Auditoria**: `created_at`, `created_by`.

#### `workflow_steps`
- **Campos**: `id (pk)`, `workflow_id (fk)`, `step_order`, `name`, `required_role_id`, `allowed_transitions (jsonb)`, `created_at`.
- **Relacionamentos**: N:1 com `workflows`, `roles`.
- **Auditoria**: `created_at`, `created_by`.

### Setor privado

#### `clients`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `name`, `document_number`, `status`, `created_at`, `updated_at`.
- **Relacionamentos**: 1:N com `contracts`, `invoices`.
- **Auditoria**: `created_at`, `updated_at`, `created_by`.

#### `contracts`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `client_id (fk)`, `start_date`, `end_date`, `value`, `status`, `created_at`.
- **Relacionamentos**: N:1 com `clients`.
- **Auditoria**: `created_at`, `created_by`.

#### `invoices`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `client_id (fk)`, `issue_date`, `due_date`, `amount`, `status`, `created_at`.
- **Relacionamentos**: N:1 com `clients`, 1:N com `accounts_receivable`.
- **Auditoria**: `created_at`, `created_by`.

#### `accounts_receivable`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `invoice_id (fk)`, `amount`, `due_date`, `status`, `created_at`.
- **Relacionamentos**: N:1 com `invoices`.
- **Auditoria**: `created_at`, `created_by`.

#### `accounts_payable`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `supplier_name`, `document_number`, `amount`, `due_date`, `status`, `created_at`.
- **Relacionamentos**: N:1 com `tenants`.
- **Auditoria**: `created_at`, `created_by`.

### Departamento pessoal (comum a PRIVATE e PUBLIC)

#### `employees`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `person_name`, `cpf`, `pis_pasep`, `birth_date`, `hire_date`, `termination_date`, `status`, `created_at`, `updated_at`.
- **Relacionamentos**: 1:N com `employment_contracts`, `payrolls`, `payslips`, `absences`, `benefit_enrollments`.
- **Auditoria**: `created_at`, `updated_at`, `created_by`.

#### `employment_contracts`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `employee_id (fk)`, `contract_type (CLT/estatutário/temporário)`, `job_title`, `workload_hours`, `salary_base`, `collective_agreement_code`, `start_date`, `end_date`, `status`, `created_at`.
- **Relacionamentos**: N:1 com `employees`.
- **Auditoria**: `created_at`, `created_by`.

#### `payrolls`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `reference_month`, `reference_year`, `status (draft/closed)`, `created_at`.
- **Relacionamentos**: 1:N com `payslips`.
- **Auditoria**: `created_at`, `created_by`.

#### `payslips` (holerites)
- **Campos**: `id (pk)`, `tenant_id (fk)`, `payroll_id (fk)`, `employee_id (fk)`, `gross_amount`, `discounts_amount`, `net_amount`, `issued_at`, `created_at`.
- **Relacionamentos**: N:1 com `payrolls`, `employees`.
- **Auditoria**: `created_at`, `created_by`.

#### `benefits`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `code`, `name`, `benefit_type (VR/VA/VT/plano_saude/outros)`, `calculation_rule (jsonb)`, `created_at`.
- **Relacionamentos**: 1:N com `benefit_enrollments`.
- **Auditoria**: `created_at`, `created_by`.

#### `benefit_enrollments`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `employee_id (fk)`, `benefit_id (fk)`, `start_date`, `end_date`, `status`, `created_at`.
- **Relacionamentos**: N:1 com `employees`, `benefits`.
- **Auditoria**: `created_at`, `created_by`.

#### `absences`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `employee_id (fk)`, `absence_type (falta/atestado/licenca/ferias)`, `start_date`, `end_date`, `legal_basis`, `status (reported/approved)`, `created_at`.
- **Relacionamentos**: N:1 com `employees`.
- **Auditoria**: `created_at`, `created_by`.

### Setor público

#### `budget_units`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `code`, `name`, `fiscal_year`, `created_at`.
- **Relacionamentos**: 1:N com `budget_allocations`.
- **Auditoria**: `created_at`, `created_by`.

#### `budget_allocations`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `budget_unit_id (fk)`, `program_code`, `action_code`, `amount`, `created_at`.
- **Relacionamentos**: N:1 com `budget_units`.
- **Auditoria**: `created_at`, `created_by`.

#### `commitments` (empenho)
- **Campos**: `id (pk)`, `tenant_id (fk)`, `budget_allocation_id (fk)`, `commitment_number`, `amount`, `status`, `created_at`.
- **Relacionamentos**: N:1 com `budget_allocations`, 1:N com `liquidations`.
- **Auditoria**: `created_at`, `created_by`.

#### `liquidations`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `commitment_id (fk)`, `liquidation_number`, `amount`, `status`, `created_at`.
- **Relacionamentos**: N:1 com `commitments`, 1:N com `payments`.
- **Auditoria**: `created_at`, `created_by`.

#### `payments`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `liquidation_id (fk)`, `payment_number`, `amount`, `status`, `created_at`.
- **Relacionamentos**: N:1 com `liquidations`.
- **Auditoria**: `created_at`, `created_by`.

#### `public_contracts`
- **Campos**: `id (pk)`, `tenant_id (fk)`, `contract_number`, `supplier_name`, `amount`, `start_date`, `end_date`, `status`, `created_at`.
- **Relacionamentos**: N:1 com `tenants`, 1:N com `commitments`.
- **Auditoria**: `created_at`, `created_by`.

---

## 3. Segurança e controle de acesso

### RBAC (Role-Based Access Control)
- Papéis por tenant (ex.: **Gestor**, **Contador**, **Fiscal**, **Compras**).
- Permissões granulares por módulo e ação (`module.action`).
- Matriz de permissões definida em `permissions` e atribuída em `role_permissions`.

### RLS no Supabase
1. **Isolamento total por tenant**:
   - Policy: `tenant_id = auth.jwt()->>'tenant_id'`.
2. **Permissões por papel**:
   - Policy: `exists (select 1 from user_roles ur join role_permissions rp on rp.role_id = ur.role_id where ur.user_id = auth.uid() and rp.permission = '...')`.
3. **Controle de módulos**:
   - Políticas bloqueiam operações caso módulo esteja desabilitado no tenant.

### Auditoria imutável
- `audit_logs` **append-only**.
- Triggers bloqueiam `UPDATE` e `DELETE`.
- Hash encadeado para integridade (ex.: `hash = sha256(prev_hash || payload)`).

---

## 4. Workflows e regras de negócio

### Privado — Pedido → Faturamento → Recebimento
**Estados**
1. Pedido (rascunho → aprovado)
2. Faturamento (emitido → entregue)
3. Recebimento (pendente → recebido)

**Transições e validações**
- Pedido só aprova com cliente ativo e contrato válido.
- Faturamento exige pedido aprovado.
- Recebimento exige nota fiscal emitida.

**Aprovações**
- Papel obrigatório: **Gestor Comercial** para aprovação de pedido.

### Público — Requisição → Empenho → Liquidação → Pagamento
**Estados**
1. Requisição (iniciada → autorizada)
2. Empenho (pré-empenho → empenhado)
3. Liquidação (em análise → liquidado)
4. Pagamento (programado → pago)

**Transições e validações**
- Empenho exige dotação orçamentária disponível.
- Liquidação exige comprovação de entrega/execução.
- Pagamento exige liquidação homologada.

**Aprovações**
- Empenho: **Ordenador de Despesa**.
- Liquidação: **Fiscal do Contrato**.
- Pagamento: **Tesouraria**.

### Departamento pessoal — Contratação → Folha → Holerite → Pagamento
**Estados**
1. Contratação (proposta → ativa)
2. Folha (aberta → fechada)
3. Holerite (gerado → entregue)
4. Pagamento (programado → pago)

**Transições e validações (legislação brasileira)**
- Contratação exige contrato válido (CLT/estatutário) e dados obrigatórios (CPF, PIS/PASEP).
- Folha só fecha com todos os eventos de proventos e descontos consolidados.
- Benefícios calculados conforme regra (VT obrigatório quando aplicável, VR/VA e plano de saúde conforme políticas).
- Faltas impactam descontos conforme tipo (falta injustificada, atestado, licença, férias) e base legal registrada.

**Aprovações**
- Fechamento da folha: **Gestor de RH**.
- Pagamento: **Financeiro/Tesouraria**.

---

## 5. Frontend (Next.js App Router)

### Estrutura de pastas
```
app/
  (public)/
  (private)/
  layout.tsx
  middleware.ts
components/
  forms/
  tables/
  workflow/
lib/
  auth/
  rbac/
  tenants/
  modules/
```

### Layouts dinâmicos por tenant_profile
- Middleware resolve `tenant_profile` após login.
- Layouts distintos carregam módulos e vocabulário apropriados.

### Controle de acesso por página
- Guardas de rota checam permissões via `rbac` e módulos habilitados.
- Redirecionamento para 403 quando não autorizado.

### Componentização
- Formulários reutilizáveis com schema por módulo.
- Tabelas padronizadas com colunas e filtros configuráveis.

---

## 6. MVP recomendado

### Núcleo comum
- Autenticação, gestão de tenants, RBAC, auditoria, documentos e workflows básicos.

### Módulo essencial privado
- **Faturamento básico** (clientes + invoices + accounts_receivable).

### Módulo essencial público
- **Empenho** (budget_units + budget_allocations + commitments).

### Fora do MVP
- Integrações bancárias.
- BI avançado.
- Gestão patrimonial completa.
- Marketplace de módulos.

---

## 7. Roadmap de evolução

### 3 meses
- MVP em produção com RBAC e workflows básicos.
- Catálogo de módulos habilitáveis por tenant.

### 6 meses
- Relatórios avançados.
- Assinatura eletrônica e trilhas completas de auditoria.
- Integrações fiscais privadas e publicas.

### 12 meses
- Marketplace de módulos.
- IA para análise de conformidade.
- Painel de custos e indicadores por unidade.

### Monetização
- Cobrança por módulo + volume de usuários.
- Plano premium com automações, integrações e suporte dedicado.

---

## 8. Boas práticas

### LGPD
- Minimização de dados.
- Consentimento explícito quando aplicável.
- Anonimização em ambientes de testes.

### Auditoria governamental
- Logs imutáveis.
- Versionamento de documentos.
- Trilhas completas de aprovação.

### Escalabilidade e performance
- Particionamento por tenant em tabelas críticas.
- Índices compostos (`tenant_id`, `status`, `created_at`).
- Cache de permissões e módulos no frontend.

### Manutenibilidade
- Schema versionado por migrações.
- Domínios isolados por módulos.
- Documentação técnica viva.
