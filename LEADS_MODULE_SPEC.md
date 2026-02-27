# Especificação Técnica: Módulo de Leads (CRM Kanban)

Este documento detalha o plano de implementação do módulo "Leads", um sistema de CRM tipo Kanban focado no gerenciamento e follow-up de conversas dentro do Hubdesk.

## 1. Visão Geral e Objetivos

O objetivo é transformar conversas e contatos em "Oportunidades" ou "Leads" que podem ser gerenciados visualmente através de estágios em um funil (Pipeline). Diferente de CRMs tradicionais focados apenas em vendas (Deal), este módulo foca no **Follow-up** e **Status do Atendimento**.

### Principais Casos de Uso:
- **Vendas**: Novo -> Contatado -> Proposta Enviada -> Negociação -> Ganho/Perdido.
- **Suporte Nível 2**: Triagem -> Em Análise -> Aguardando Dev -> Resolvido.
- **Onboarding**: Início -> Configuração -> Treinamento -> Concluído.

---

## 2. Arquitetura de Dados (Backend)

Novos modelos serão criados sob o namespace `Crm` para manter a organização.

### 2.1. Modelos (ERD)

#### `Crm::Pipeline`
Representa um fluxo de trabalho (ex: "Vendas", "Suporte").
- `account_id` (FK)
- `name` (String)
- `display_order` (Integer)

#### `Crm::Stage`
Representa as colunas do Kanban.
- `crm_pipeline_id` (FK)
- `name` (String)
- `type` (Enum: `standard`, `won`, `lost`) - Para métricas futuras.
- `display_order` (Integer)

#### `Crm::Lead`
O "Card" que viaja pelo Kanban.
- `account_id` (FK)
- `crm_stage_id` (FK) - Onde ele está agora.
- `contact_id` (FK) - Quem é o cliente.
- `conversation_id` (FK, Opcional) - Qual conversa gerou este lead.
- `user_id` (FK, Opcional) - Responsável pelo lead (pode ser diferente do assignee da conversa).
- `title` (String) - Ex: "Interesse no Plano Enterprise".
- `value` (Decimal, Opcional) - Valor monetário estimado.
- `expected_closing_at` (Datetime, Opcional) - Previsão.
- `priority` (Enum: `low`, `medium`, `high`).

### 2.2. Relacionamentos
- `Account` has_many `Crm::Pipelines`
- `Crm::Pipeline` has_many `Crm::Stages`
- `Crm::Stage` has_many `Crm::Leads`
- `Contact` has_many `Crm::Leads`

---

## 3. API e Endpoints

Seguindo o padrão RESTful em `Api::V1::Accounts::Crm`.

- `GET /pipelines`: Listar pipelines com seus estágios.
- `POST /pipelines`: Criar pipeline.
- `GET /pipelines/:id/leads`: Buscar leads de um pipeline (agrupados por estágio ou lista flat).
- `POST /leads`: Criar um lead (manual ou via modal na conversa).
- `PATCH /leads/:id`: Mover de estágio (Drag & Drop), editar valores.
- `DELETE /leads/:id`: Arquivar lead.

---

## 4. Frontend (Vue.js)

### 4.1. Estrutura de Diretórios
```
dashboard/
├── api/
│   └── leads.js           # Cliente API
├── store/modules/
│   └── leads/             # Store Vuex (Pipelines, Stages, Leads)
├── routes/dashboard/
│   └── leads/
│       ├── leads.routes.js
│       ├── Index.vue      # Layout Principal
│       ├── components/
│       │   ├── KanbanBoard.vue
│       │   ├── KanbanColumn.vue
│       │   ├── LeadCard.vue
│       │   ├── PipelineSelector.vue
│       │   └── LeadFormModal.vue
```

### 4.2. Componentes Chave
- **KanbanBoard**: Utilizará `vuedraggable` para permitir arrastar Cards entre Colunas (Stages).
- **LeadCard**: Mostrará:
    - Avatar do Contato.
    - Título do Lead.
    - Valor (se houver).
    - Badge de Prioridade.
    - Ícone de "Conversa Ativa" (link direto para a inbox).
    - Avatar do Responsável.

### 4.3. Integração com Conversas
- Adicionar um botão no **Painel de Detalhes da Conversa** (Conversation Sidebar) para "Criar Lead" ou "Ver Lead".
- Isso permite que o agente crie o lead sem sair do atendimento.

---

## 5. Plano de Implementação (Passo a Passo)

### Fase 1: Estrutura Base (Backend)
1.  [ ] Criar Migrations e Models (`Pipeline`, `Stage`, `Lead`).
2.  [ ] Criar Policies (Pundit) para controle de acesso.
3.  [ ] Implementar Controllers e Views JSON.
4.  [ ] Adicionar testes RSpec.

### Fase 2: Interface Kanban (Frontend)
1.  [ ] Criar Store Vuex (`leads`).
2.  [ ] Implementar API Client.
3.  [ ] Criar tela principal (`/leads`) com seletor de Pipeline.
4.  [ ] Implementar Kanban Board com `vuedraggable`.
5.  [ ] Implementar persistência do movimento (API call ao soltar o card).

### Fase 3: Detalhes e Integração
1.  [ ] Criar Modal de Criação/Edição de Lead.
2.  [ ] Integrar botão "Gerar Lead" na tela de Conversa.
3.  [ ] Adicionar filtros (Meus Leads, Prioridade).

### Fase 4: Refinamento
1.  [ ] Internacionalização (i18n).
2.  [ ] Websockets (atualizar Kanban se outro usuário mover um card).

---

## 6. Pontos de Atenção
- **Performance**: Carregar muitos leads no Kanban pode ser pesado. Implementar paginação ou "Load More" por coluna se necessário.
- **Permissões**: Definir se agentes podem ver leads de outros agentes (provavelmente configurável ou baseado nas permissões de equipe existentes).
