# Synapsea Connect — Arquitetura de Plataforma (Mapa do Cérebro)

## 1) Objetivo desta fase

Definir a arquitetura completa para transformar o Connect em **plataforma de operação conversacional com IA e agentes**, com evolução segura sobre o core do Connect.

---

## 2) Estado atual (base já existente)

- **Core operacional**: Connect (Rails + Vue + Sidekiq + PostgreSQL + Redis + Vite).
- **Canal principal de operação**: conversas/inbox/contatos já consolidados.
- **Capacidade de extensão**: webhooks, jobs assíncronos, automações e módulos de UI.

Diretriz: preservar o core para facilitar upgrades; novas capacidades entram como camadas acopladas por contratos estáveis.

---

## 3) Princípio arquitetural

Adotar arquitetura em camadas:

1. **Conversation Core (Connect)**
2. **Event & Integration Layer**
3. **Intelligence Layer (AI + RAG)**
4. **Agent Runtime Layer**
5. **Operational Analytics Layer**
6. **Executive Insights Layer**

Cada camada deve ser habilitável por feature flag por tenant.

---

## 4) Mapa de serviços (alto nível)

```text
[Channels: WhatsApp, Webchat, Email, Instagram]
                |
                v
      [Synapsea Connect Core]
  (Rails API + Vue App + Sidekiq)
                |
                | Domain Events / Webhooks
                v
     [Event Gateway / Orchestrator]
       (Node.js ou Rails-only mode)
        |            |            |
        |            |            |
        v            v            v
 [AI Service]   [Agent Runtime] [Analytics ETL]
 (LLM + RAG)   (SDR/Suporte/   (OLAP + métricas
                Cobrança/Onb)    operacionais)
        |            |            |
        v            v            v
 [Vector DB]   [Action APIs]   [Warehouse/Views]
 (pgvector)    (CRM, agenda,    (Postgres read
               tickets, etc.)    models)
```

---

## 5) Camada de Inteligência (IA Operacional)

### 5.1 Fluxo recomendado

1. Evento de conversa (nova msg, mudança de status, atribuição).
2. Publicação no Event Gateway.
3. Orquestração por tipo de tarefa:
   - resumo automático,
   - intenção,
   - classificação de lead,
   - sugestão de resposta.
4. Chamada ao AI Service com contexto + memória (RAG).
5. Persistência do resultado estruturado (JSON) em store dedicado.
6. Exibição no painel lateral via API estável.

### 5.2 Contrato de resposta (exemplo)

```json
{
  "conversation_id": 123,
  "summary": "Cliente solicitou atualização de proposta e prazo de implantação.",
  "intent": "pricing_negotiation",
  "lead_score": 78,
  "lead_stage": "qualified",
  "reply_suggestions": [
    "Posso te enviar a proposta atualizada ainda hoje.",
    "Quer agendar uma call de 15 minutos para validar escopo?"
  ],
  "confidence": 0.89,
  "generated_at": "2026-03-12T00:00:00Z"
}
```

### 5.3 RAG mínimo

- Fonte inicial: histórico da conversa + notas internas + KB.
- Vector DB: `pgvector` (pode iniciar no mesmo Postgres para reduzir complexidade).
- Evolução: separar para cluster dedicado quando throughput justificar.

---

## 6) Camada CRM Inteligente embutido

### 6.1 Modelo mínimo por contato

- empresa
- cargo
- origem do lead
- estágio do funil
- score de qualificação
- histórico resumido de interação

### 6.2 Estratégia de dados

- Evitar hardfork de modelo core no início.
- Preferir:
  - `additional_attributes` para MVP,
  - migração posterior para tabela dedicada (`contact_business_profiles`) quando houver necessidade de query analítica pesada.

### 6.3 Contrato de UI

`GET /api/v1/accounts/:id/contacts/:id/business_profile`

Resposta:

```json
{
  "company": "Acme Ltda",
  "job_title": "Head de Operações",
  "lead_source": "whatsapp_campaign",
  "funnel_stage": "proposal",
  "qualification_score": 82,
  "interaction_history": "3 conversas nos últimos 30 dias"
}
```

---

## 7) Camada de agentes autônomos

### 7.1 Agent Runtime

Cada agente deve seguir mesmo contrato:

- `input`: contexto + objetivo + políticas
- `decision`: ação proposta
- `execution`: chamada a tool/API
- `handoff`: transferência para humano quando necessário

### 7.2 Agentes iniciais

- SDR AI
- Suporte AI
- Cobrança AI
- Onboarding AI

### 7.3 Guardrails obrigatórios

- limites por tenant (rate/custo)
- trilha de auditoria de ações
- escopo de ferramentas por perfil
- fallback explícito para humano

---

## 8) Camada de automação (motor de processos)

### 8.1 Trigger → Condition → Action

- Trigger: evento de mensagem/status/tag
- Condition: regras por canal, prioridade, intent, score
- Action: etiqueta, atribuição, webhook, agente, SLA

### 8.2 Estratégia

- Reutilizar engine atual de automação do Connect para MVP.
- Introduzir novos action types versionados (`ai.summarize`, `agent.assign`, etc.).

---

## 9) Camada de analytics operacional

### 9.1 Métricas essenciais

- tempo médio de primeira resposta
- tempo de resolução
- conversão de leads
- produtividade por agente
- origem dos contatos

### 9.2 Arquitetura de dados

- **Write path**: eventos transacionais no core.
- **Read path**: materialized views / tabelas agregadas para dashboards.
- Atualização: near-real-time (1–5 min) via jobs assíncronos.

---

## 10) Painel executivo

Visão para liderança:

- volume de conversas
- oportunidades geradas
- taxa de qualificação
- gargalos por etapa
- custo operacional por canal/agente

Importante: KPIs com definição formal (dicionário de métricas) para evitar ambiguidade comercial.

---

## 11) Multi-tenant e SaaS readiness

### 11.1 Isolamento

- tenant_id em todas as entidades de extensão
- particionamento lógico por conta
- criptografia de dados sensíveis em repouso

### 11.2 Billing/módulos

Planos por capacidade:

- Core
- AI Assist
- CRM+ Insights
- Agent Platform

Entitlement por feature flag no backend + gate de UI.

---

## 12) Segurança e governança

- RBAC por ação de agente
- logging estruturado de prompts e respostas (com redaction)
- políticas LGPD: retenção, anonimização, exportação
- observabilidade: tracing por pipeline (evento → inferência → UI)

---

## 13) Plano de execução (90 dias)

### Sprint A (Semanas 1–3)

- Contratos de evento + AI payload
- Store de insights por conversa
- UI lateral consumindo API real

### Sprint B (Semanas 4–6)

- CRM embutido com perfil de negócio
- Automações com ações IA básicas
- Dashboard operacional v1

### Sprint C (Semanas 7–9)

- Agent runtime v1 (SDR + Suporte)
- Guardrails + auditoria
- Executive panel v1

### Sprint D (Semanas 10–12)

- hardening, custos, SLOs
- rollout gradual por tenant
- playbook comercial por módulo

---

## 14) Riscos e mitigação

- **Drift de fork**: mitigar via extensão por módulos e contratos, evitando mexer no core sem necessidade.
- **Custo de IA**: cache de inferência + políticas de frequência + modelos por tier.
- **Qualidade inconsistente**: avaliação contínua (offline + online) com datasets reais.
- **Sobrecarga operacional**: observabilidade e circuit breakers por serviço.

---

## 15) Decisão recomendada agora

Próxima entrega técnica deve ser um **Architecture Decision Record (ADR) set** com:

1. Event contract versioning
2. AI service boundary (Rails vs Node gateway)
3. Data model CRM (additional_attributes vs tabela dedicada)
4. Analytics read model strategy
5. Agent guardrails e auditoria

Com isso, o Connect sai do estágio de “customização” e entra no estágio de “plataforma de receita”.
