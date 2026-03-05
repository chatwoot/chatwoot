# AirysChat — Estratégia de Precificação

> Documento de planejamento de planos, custos e margens para a plataforma AirysChat.
> Última atualização: Julho 2025

---

## Sumário

1. [Inventário de Funcionalidades](#1-inventário-de-funcionalidades)
2. [Análise de Custos Reais](#2-análise-de-custos-reais)
3. [Estrutura de Planos](#3-estrutura-de-planos)
4. [Distribuição de Funcionalidades por Plano](#4-distribuição-de-funcionalidades-por-plano)
5. [Tabela de Preços Final](#5-tabela-de-preços-final)
6. [Análise de Margem e Break-Even](#6-análise-de-margem-e-break-even)
7. [Plano de Implementação](#7-plano-de-implementação)

---

## 1. Inventário de Funcionalidades

### 1.1 Canais de Comunicação (13 canais)

| Canal | Descrição |
|-------|-----------|
| **Web Widget** | Chat ao vivo embarcado em sites |
| **WhatsApp** | WhatsApp Business API (Cloud API + 360dialog) |
| **Facebook Messenger** | Mensagens de páginas do Facebook |
| **Instagram** | Direct Messages do Instagram |
| **TikTok** | DMs do TikTok |
| **Telegram** | Mensagens via Bot do Telegram |
| **Email** | Inbound/outbound (IMAP/SMTP, OAuth Google/Microsoft) |
| **SMS (Bandwidth)** | SMS via Bandwidth API |
| **Twilio SMS/WhatsApp** | SMS e WhatsApp via Twilio |
| **LINE** | Mensagens LINE |
| **Twitter/X** | DMs do Twitter (depreciado) |
| **API** | Canal headless para integrações customizadas |
| **Voz** | Chamadas telefônicas via Twilio (premium) |

### 1.2 Funcionalidades de IA / Captain (11 itens core)

| Funcionalidade | Descrição |
|----------------|-----------|
| **Assistente de Escrita (Editor)** | Reescrita, ajuste de tom, correção gramatical com IA |
| **Captain Assistant** | Bot de auto-resposta com LLM + base de conhecimento |
| **Captain Copilot** | Sugestões de resposta em tempo real para agentes |
| **Sugestões de Resposta** | Respostas contextuais sugeridas pela IA |
| **Resumo de Conversa** | Resumos automáticos gerados por IA |
| **Detecção de Follow-Up** | Identifica conversas que precisam de acompanhamento |
| **Sugestão de Labels** | Auto-sugestão de etiquetas para conversas |
| **Análise CSAT** | Análise de IA sobre respostas de satisfação |
| **Transcrição de Áudio** | Transcrição de mensagens de voz (Whisper) |
| **Captain Tasks** | Operações baseadas em tarefas com IA |
| **Preferências Captain** | Configuração de modelo/feature por conta |

### 1.3 AI Agent Builder (11 itens customizados SaaS)

| Funcionalidade | Descrição |
|----------------|-----------|
| **Agentes IA (4 tipos)** | RAG, Tool Calling, Voice, Hybrid |
| **Vinculação a Inboxes** | Conectar agentes IA a caixas de entrada |
| **Preview/Sandbox** | Testar agentes antes de publicar |
| **Knowledge Bases** | Bases de conhecimento para RAG |
| **Knowledge Documents** | Upload de arquivos, URLs, texto → chunking + embedding |
| **Pipeline RAG** | Crawling, chunking, embedding, busca semântica |
| **Agent Tools (Function Calling)** | Ferramentas HTTP, handoff, built-in com Liquid templates |
| **Editor Visual de Workflows** | Engine de workflows baseada em grafos |
| **Histórico de Execuções** | Logs, tokens, rastreamento por execução |
| **Validador de Workflows** | Validação da estrutura antes de salvar |
| **Prompt Builder Modular** | Composição modular de system prompts |

#### Nós de Workflow (12 tipos)

`trigger` · `system_prompt` · `knowledge_retrieval` · `llm_call` · `condition` · `loop` · `set_variable` · `delay` · `http_request` · `handoff` · `reply` · `code`

### 1.4 LLM Proxy & Modelos Disponíveis

| Provider | Modelos | Custo Relativo |
|----------|---------|----------------|
| **OpenAI** | GPT-4.1, GPT-4.1 Mini, GPT-4.1 Nano, GPT-5.1, GPT-5 Mini, GPT-5 Nano, GPT-5.2 | ⭐ a ⭐⭐⭐ |
| **OpenAI (Áudio)** | Whisper-1, TTS-1, TTS-1 HD | ⭐ a ⭐⭐ |
| **OpenAI (Realtime)** | GPT Realtime, GPT Realtime Mini | ⭐⭐⭐⭐⭐ |
| **Anthropic** | Claude Haiku 4.5, Claude Sonnet 4.5 | ⭐⭐ a ⭐⭐⭐ |
| **Google** | Gemini 3 Flash, Gemini 3 Pro | ⭐ a ⭐⭐⭐ |
| **ElevenLabs** | Turbo v2.5, Multilingual v2 | ⭐⭐ a ⭐⭐⭐ |

**Total: 19 modelos** com `credit_multiplier` de 1x a 5x.

### 1.5 Voz / Telefonia (11 itens — Premium)

- Canal de voz (Twilio inbound/outbound)
- Agentes de voz IA
- Catálogo de vozes (11 OpenAI + ElevenLabs)
- Preview de voz
- Ponte Twilio ↔ OpenAI/ElevenLabs Realtime
- Sessão WebSocket em tempo real
- Pipeline de fallback (STT → LLM → TTS)
- TTS via ElevenLabs
- Provider OpenAI Realtime
- Provider ElevenLabs Conversational AI
- Webhooks Twilio (incoming, status, fallback)

### 1.6 Automação e Workflows

- **Regras de Automação**: 17 condições × 15+ ações
- **Macros**: Sequências salvas de ações
- **Agent Bots**: Bots externos via webhook

### 1.7 Relatórios e Analytics (10 tipos)

Relatórios de Conversa · Summary · Live · Bot Metrics · Inbox-Label Matrix · Distribuição FRT · Volume de Mensagens · Tráfego de Conversas · Exportação CSV · Pesquisa CSAT com análise IA

### 1.8 CRM / Gestão de Contatos (11 itens)

Contatos CRUD · Labels · Histórico · Merge · Import CSV · Export · Atributos Customizados · Filtros Customizados · Notas · Empresas (premium) · Busca

### 1.9 Funcionalidades de Conversa (17 itens)

Gerenciamento de conversas · Mensagens e anexos · Drafts · Labels · Assignments · Participantes · @Mentions · Canned Responses · Campanhas · Ações em lote · Políticas SLA (premium) · Auto-resolve · Busca full-text · Upload direto · Reply-to · Atributos obrigatórios (premium) · Prioridades

### 1.10 WhatsApp-Específico (8 itens)

Cloud API · 360dialog · Templates de mensagem · Template Builder · WhatsApp Flows · Campanhas WhatsApp · Templates CSAT · Embedded Signup

### 1.11 Time e Equipe (9 itens)

Agentes · Equipes · Roles customizados (premium) · Políticas de atribuição · Atribuição por inbox · Agentes disponíveis · Horário comercial · Configurações de notificação · Atribuição avançada (premium)

### 1.12 Integrações (11)

Slack · Webhooks · Dashboard Apps · Dialogflow · OpenAI · Google Translate · Dyte (vídeo) · Linear · Notion · Shopify · LeadSquared CRM

### 1.13 Help Center (4 itens)

Portais multi-domínio · Artigos · Categorias · Busca semântica via embeddings (premium)

### 1.14 Segurança e Enterprise (4 itens)

SAML SSO · 2FA (TOTP) · Audit Logs (premium) · Custom Roles (premium)

### 1.15 Customização e Branding (5 itens)

Remoção de branding (premium) · Email de resposta customizado · Domínio de resposta customizado · IP Lookup · White-labeling

### 1.16 API e Desenvolvimento

Platform API · Account API (REST completa) · Webhooks de conta · Agent Bot Webhooks · Web Widget SDK · Documentação Swagger

---

## 2. Análise de Custos Reais

### 2.1 Infraestrutura Fixa (mensal)

| Item | Custo EUR | Custo BRL* | Notas |
|------|-----------|-----------|-------|
| **Hetzner CCX23** | €38,90 | R$225,00 | 4 vCPU AMD, 16 GB RAM, 160 GB SSD |
| **Backup Hetzner (20%)** | €7,78 | R$45,00 | Backup automático do servidor |
| **Domínio (.com.br)** | — | R$5,00 | ~R$60/ano |
| **SMTP (Google Workspace)** | — | R$28,00 | Conta info@airys.com.br |
| **SSL** | — | R$0 | Let's Encrypt (gratuito) |
| **LiteLLM Proxy** | — | R$0 | Self-hosted, mesmo servidor |
| **Redis/PostgreSQL** | — | R$0 | Docker no mesmo servidor |
| **Monitoramento** | — | R$0 | Básico incluso no Hetzner |
| **Total Fixo** | **~€47** | **~R$303,00** | |

> *Câmbio utilizado: 1 EUR = R$5,78 (referência Jul/2025)

### 2.2 Custos Variáveis — OpenAI API

| Modelo | Input ($/1M tokens) | Output ($/1M tokens) | Uso Típico |
|--------|---------------------|----------------------|------------|
| **GPT-4.1 Nano** | $0,10 | $0,40 | Label suggestion, tarefas simples |
| **GPT-4.1 Mini** | $0,40 | $1,60 | Editor IA, assistente rápido |
| **GPT-4.1** | $2,00 | $8,00 | Assistant, Copilot, Agent Builder |
| **GPT-5 Nano** | $0,15 | $0,60 | Budget tasks |
| **GPT-5 Mini** | $1,10 | $4,40 | Voice Agent backend |
| **GPT-5.1** | $3,00 | $12,00 | Assistant principal, Copilot |
| **GPT-5.2** | $4,00 | $16,00 | Análises complexas |
| **Whisper-1** | $0,006/min | — | Transcrição de áudio |
| **TTS-1** | $15,00/1M chars | — | Text-to-speech |
| **TTS-1 HD** | $30,00/1M chars | — | Text-to-speech premium |
| **Text Embedding 3 Small** | $0,02/1M tokens | — | Embeddings RAG |
| **GPT Realtime** | $5,00/1M audio tokens | $20,00/1M | Voz em tempo real |
| **GPT Realtime Mini** | $2,50/1M audio tokens | $10,00/1M | Voz realtime econômico |

#### Estimativa de custo IA por plano

| Cenário | Tokens/mês | Modelo médio ponderado | Custo bruto USD | Custo BRL* |
|---------|------------|------------------------|-----------------|-----------|
| Uso leve (10K tokens) | 10.000 | GPT-4.1 Mini | ~$0,02 | R$0,12 |
| Uso básico (100K tokens) | 100.000 | GPT-4.1 Mini + Nano | ~$0,10 | R$0,58 |
| Uso moderado (500K tokens) | 500.000 | Mix Mini/4.1/5.1 | ~$1,50 | R$8,70 |
| Uso intenso (2M tokens) | 2.000.000 | Mix 4.1/5.1/5.2 | ~$8,00 | R$46,40 |
| Uso pesado (5M tokens) | 5.000.000 | Mix avançado | ~$25,00 | R$145,00 |
| Voz (1h realtime) | ~60M audio tokens | GPT Realtime | ~$300+ | R$1.740+ |

> *Câmbio: 1 USD = R$5,80

### 2.3 Custos Variáveis — ElevenLabs

| Plano ElevenLabs | Preço USD/mês | Caracteres | Custo por 1K chars |
|------------------|---------------|-----------|-------------------|
| Starter | $5 | 30.000 | $0,17 |
| Creator | $22 | 100.000 | $0,22 |
| Pro | $99 | 500.000 | $0,20 |
| Scale | $330 | 2.000.000 | $0,17 |
| Business | $1.320 | 11.000.000 | $0,12 |

> Custo ElevenLabs estimado: **R$0,87 — R$1,27 por 1.000 caracteres sintetizados.**

### 2.4 Taxas do Stripe (Brasil)

| Tipo de Transação | Taxa |
|-------------------|------|
| Cartão nacional | 3,99% + R$0,39 |
| Cartão internacional | 5,99% + R$0,39 |
| Boleto (via Stripe) | 3,99% + R$3,49 |
| PIX (via Stripe) | 2,99% + R$0,39 |

> **Para cálculos, usaremos 4,5% + R$0,39** como taxa média ponderada.

### 2.5 Resumo de Custos Operacionais

| Categoria | Custo Mensal | Tipo |
|-----------|-------------|------|
| Infraestrutura (servidor + backup) | R$270,00 | Fixo |
| SMTP/Email | R$28,00 | Fixo |
| Domínio | R$5,00 | Fixo |
| **Total Fixo** | **R$303,00** | — |
| IA (por cliente médio) | R$5 — R$150 | Variável |
| Stripe (por transação) | ~4,5% + R$0,39 | Variável |
| Voz/ElevenLabs (por cliente) | R$0 — R$500+ | Variável premium |

---

## 3. Estrutura de Planos

### 3.1 Filosofia de Precificação

1. **Preço mínimo: R$389,90/mês** — cobre custos fixos de infra + margem saudável
2. **Sem plano gratuito permanente** — oferecemos trial de 14 dias com acesso ao plano Essencial
3. **Planos anuais com 20% de desconto** — incentiva retenção e previsibilidade de receita
4. **IA como diferencial de valor** — tokens de IA são o principal driver de custo e valor
5. **Voz como premium** — funcionalidade de voz IA apenas em planos superiores (custo elevado)
6. **Escala progressiva** — mais agentes, inboxes e tokens conforme o plano sobe

### 3.2 Definição dos Planos

| | 🟢 **Essencial** | 🔵 **Profissional** | 🟡 **Business** | 🔴 **Enterprise** |
|---|---|---|---|---|
| **Preço Mensal** | R$389,90 | R$789,90 | R$1.289,90 | R$2.489,90 |
| **Preço Anual** (20% off) | R$311,92/mês (R$3.743,04/ano) | R$631,92/mês (R$7.583,04/ano) | R$1.031,92/mês (R$12.383,04/ano) | R$1.991,92/mês (R$23.903,04/ano) |
| **Agentes** | 5 | 15 | 40 | 100 |
| **Caixas de Entrada** | 5 | 20 | 60 | 200 |
| **Tokens IA/mês** | 100.000 | 500.000 | 2.000.000 | 10.000.000 |

### 3.3 Período de Trial

- **14 dias grátis** com funcionalidades do plano Essencial
- Necessário cartão de crédito para iniciar
- Ao final do trial o plano inicia automaticamente
- Email de lembrete nos dias 5, 10 e 15

---

## 4. Distribuição de Funcionalidades por Plano

### 4.1 Canais de Comunicação

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| Web Widget | ✅ | ✅ | ✅ | ✅ |
| Email | ✅ | ✅ | ✅ | ✅ |
| WhatsApp Cloud API | ✅ | ✅ | ✅ | ✅ |
| Facebook Messenger | ✅ | ✅ | ✅ | ✅ |
| Instagram | — | ✅ | ✅ | ✅ |
| Telegram | ✅ | ✅ | ✅ | ✅ |
| TikTok | — | ✅ | ✅ | ✅ |
| SMS (Bandwidth/Twilio) | — | ✅ | ✅ | ✅ |
| LINE | — | ✅ | ✅ | ✅ |
| Canal API (Headless) | — | ✅ | ✅ | ✅ |
| **Voz (Twilio)** | — | — | ✅ | ✅ |

### 4.2 Inteligência Artificial

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| Assistente de Escrita (Editor IA) | ✅ | ✅ | ✅ | ✅ |
| Transcrição de Áudio (Whisper) | ✅ | ✅ | ✅ | ✅ |
| Sugestão de Labels | ✅ | ✅ | ✅ | ✅ |
| Captain Copilot (sugestões de resposta) | — | ✅ | ✅ | ✅ |
| Resumo de Conversa | — | ✅ | ✅ | ✅ |
| Detecção de Follow-Up | — | ✅ | ✅ | ✅ |
| Captain Assistant (bot de auto-resposta) | — | ✅ | ✅ | ✅ |
| Análise CSAT com IA | — | — | ✅ | ✅ |
| Captain Tasks | — | — | ✅ | ✅ |

### 4.3 AI Agent Builder (Custom SaaS)

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| Agentes IA (RAG) | — | 1 agente | 5 agentes | Ilimitado |
| Agentes IA (Tool Calling) | — | — | 5 agentes | Ilimitado |
| Agentes IA (Hybrid) | — | — | 2 agentes | Ilimitado |
| **Agentes IA (Voice)** | — | — | 2 agentes | Ilimitado |
| Knowledge Bases | — | 1 | 10 | Ilimitado |
| Knowledge Documents | — | 50 docs | 500 docs | Ilimitado |
| Editor Visual de Workflows | — | — | ✅ | ✅ |
| Agent Tools (Function Calling) | — | 3 tools | 20 tools | Ilimitado |
| Preview/Sandbox | — | ✅ | ✅ | ✅ |
| Histórico de Execuções | — | 7 dias | 90 dias | 365 dias |
| Todos os 12 nós de workflow | — | — | ✅ | ✅ |

### 4.4 Modelos LLM Disponíveis

| Modelo | Essencial | Profissional | Business | Enterprise |
|--------|:---------:|:------------:|:--------:|:----------:|
| GPT-4.1 Nano | ✅ | ✅ | ✅ | ✅ |
| GPT-4.1 Mini | ✅ | ✅ | ✅ | ✅ |
| GPT-5 Nano | ✅ | ✅ | ✅ | ✅ |
| GPT-5 Mini | — | ✅ | ✅ | ✅ |
| GPT-4.1 | — | ✅ | ✅ | ✅ |
| GPT-5.1 | — | — | ✅ | ✅ |
| GPT-5.2 | — | — | — | ✅ |
| Claude Haiku 4.5 | — | — | ✅ | ✅ |
| Claude Sonnet 4.5 | — | — | — | ✅ |
| Gemini 3 Flash | — | ✅ | ✅ | ✅ |
| Gemini 3 Pro | — | — | ✅ | ✅ |
| Whisper-1 | ✅ | ✅ | ✅ | ✅ |
| Text Embedding 3 Small | — | ✅ | ✅ | ✅ |
| TTS-1 | — | — | ✅ | ✅ |
| TTS-1 HD | — | — | — | ✅ |
| GPT Realtime Mini | — | — | ✅ | ✅ |
| GPT Realtime | — | — | — | ✅ |
| ElevenLabs Turbo v2.5 | — | — | ✅ | ✅ |
| ElevenLabs Multilingual v2 | — | — | — | ✅ |

### 4.5 Voz / Telefonia

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| Canal de Voz (Twilio) | — | — | ✅ | ✅ |
| Agentes de Voz IA | — | — | 2 agentes | Ilimitado |
| Catálogo de Vozes | — | — | ✅ | ✅ |
| Preview de Voz | — | — | ✅ | ✅ |
| Realtime OpenAI | — | — | ✅ (Mini) | ✅ (Full) |
| ElevenLabs Conversational | — | — | ✅ (Turbo) | ✅ (Multi) |
| Pipeline de Fallback | — | — | ✅ | ✅ |
| Minutos de Voz/mês | — | — | 60 min | 300 min |

### 4.6 Automação e Workflows

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| Regras de Automação | 5 regras | 25 regras | 100 regras | Ilimitado |
| Macros | 10 | 50 | 200 | Ilimitado |
| Agent Bots (Webhook) | — | 2 | 10 | Ilimitado |
| Campanhas (Website) | — | ✅ | ✅ | ✅ |
| Campanhas WhatsApp | — | — | ✅ | ✅ |

### 4.7 Relatórios e Analytics

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| Relatórios Básicos | ✅ | ✅ | ✅ | ✅ |
| Relatórios de Conversa | ✅ | ✅ | ✅ | ✅ |
| Summary Reports | — | ✅ | ✅ | ✅ |
| Live Reports (tempo real) | — | ✅ | ✅ | ✅ |
| Bot Metrics | — | — | ✅ | ✅ |
| Inbox-Label Matrix | — | — | ✅ | ✅ |
| Distribuição FRT | — | — | ✅ | ✅ |
| Tráfego de Conversas | — | — | ✅ | ✅ |
| Exportação CSV | — | ✅ | ✅ | ✅ |
| Pesquisa CSAT + Análise IA | — | — | ✅ | ✅ |

### 4.8 CRM / Contatos

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| Contatos CRUD | ✅ | ✅ | ✅ | ✅ |
| Labels de Contato | ✅ | ✅ | ✅ | ✅ |
| Histórico de Conversas | ✅ | ✅ | ✅ | ✅ |
| Notas | ✅ | ✅ | ✅ | ✅ |
| Merge de Contatos | — | ✅ | ✅ | ✅ |
| Import/Export CSV | — | ✅ | ✅ | ✅ |
| Atributos Customizados | — | ✅ | ✅ | ✅ |
| Filtros Customizados | — | ✅ | ✅ | ✅ |
| Busca Avançada | — | — | ✅ | ✅ |
| Empresas (Organizações) | — | — | — | ✅ |

### 4.9 WhatsApp Avançado

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| WhatsApp Cloud API | ✅ | ✅ | ✅ | ✅ |
| Templates de Mensagem | ✅ | ✅ | ✅ | ✅ |
| Template Builder Visual | — | ✅ | ✅ | ✅ |
| WhatsApp Flows | — | — | ✅ | ✅ |
| Campanhas WhatsApp | — | — | ✅ | ✅ |
| Templates CSAT | — | — | ✅ | ✅ |

### 4.10 Time e Equipe

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| Gestão de Agentes | ✅ | ✅ | ✅ | ✅ |
| Equipes | ✅ | ✅ | ✅ | ✅ |
| Horário Comercial | ✅ | ✅ | ✅ | ✅ |
| Notificações Customizadas | ✅ | ✅ | ✅ | ✅ |
| Políticas de Atribuição | — | ✅ | ✅ | ✅ |
| Atribuição por Inbox | — | ✅ | ✅ | ✅ |
| Atribuição Avançada | — | — | ✅ | ✅ |
| Roles Customizados | — | — | — | ✅ |

### 4.11 Integrações

| Integração | Essencial | Profissional | Business | Enterprise |
|------------|:---------:|:------------:|:--------:|:----------:|
| Webhooks | ✅ | ✅ | ✅ | ✅ |
| Slack | — | ✅ | ✅ | ✅ |
| Dashboard Apps | — | ✅ | ✅ | ✅ |
| Google Translate | — | ✅ | ✅ | ✅ |
| Dialogflow | — | — | ✅ | ✅ |
| Dyte (Vídeo/Áudio) | — | — | ✅ | ✅ |
| Linear | — | — | ✅ | ✅ |
| Notion | — | — | ✅ | ✅ |
| Shopify | — | — | — | ✅ |
| LeadSquared CRM | — | — | — | ✅ |

### 4.12 Help Center

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| Portal de Ajuda | — | 1 portal | 3 portais | Ilimitado |
| Artigos | — | 50 artigos | 500 artigos | Ilimitado |
| Categorias | — | ✅ | ✅ | ✅ |
| Busca Semântica (Embeddings) | — | — | ✅ | ✅ |

### 4.13 Segurança e Compliance

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| 2FA (TOTP) | ✅ | ✅ | ✅ | ✅ |
| SAML SSO | — | — | — | ✅ |
| Audit Logs | — | — | ✅ | ✅ |

### 4.14 Customização e Branding

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| IP Lookup (GeoIP) | — | ✅ | ✅ | ✅ |
| Email de Resposta Custom | — | — | ✅ | ✅ |
| Domínio de Resposta Custom | — | — | — | ✅ |
| Remoção de Branding | — | — | — | ✅ |
| White-labeling | — | — | — | ✅ |

### 4.15 SLA

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| Políticas SLA | — | — | 3 políticas | Ilimitado |
| Atributos Obrigatórios | — | — | ✅ | ✅ |
| Auto-resolve Configurável | ✅ | ✅ | ✅ | ✅ |

### 4.16 API e Desenvolvimento

| Funcionalidade | Essencial | Profissional | Business | Enterprise |
|----------------|:---------:|:------------:|:--------:|:----------:|
| Account API (REST) | ✅ | ✅ | ✅ | ✅ |
| Web Widget SDK | ✅ | ✅ | ✅ | ✅ |
| Rate Limit (req/min) | 60 | 300 | 600 | 1.200 |
| Webhooks de Conta | 1 | 5 | 20 | Ilimitado |
| Platform API | — | — | — | ✅ |
| Documentação Swagger | ✅ | ✅ | ✅ | ✅ |

---

## 5. Tabela de Preços Final

### 5.1 Preços Mensais

| Plano | Preço/mês | Agentes | Inboxes | Tokens IA/mês | Público-alvo |
|-------|-----------|---------|---------|---------------|-------------|
| 🟢 **Essencial** | **R$389,90** | 5 | 5 | 100K | Pequenas empresas, autônomos |
| 🔵 **Profissional** | **R$789,90** | 15 | 20 | 500K | Empresas em crescimento |
| 🟡 **Business** | **R$1.289,90** | 40 | 60 | 2M | Operações maduras, voz IA |
| 🔴 **Enterprise** | **R$2.489,90** | 100 | 200 | 10M | Grandes operações, white-label |

### 5.2 Preços Anuais (20% de desconto)

| Plano | Preço/mês (anual) | Total/ano | Economia |
|-------|-------------------|-----------|----------|
| 🟢 **Essencial** | **R$311,92/mês** | R$3.743,04 | R$935,76 |
| 🔵 **Profissional** | **R$631,92/mês** | R$7.583,04 | R$1.895,76 |
| 🟡 **Business** | **R$1.031,92/mês** | R$12.383,04 | R$3.095,76 |
| 🔴 **Enterprise** | **R$1.991,92/mês** | R$23.903,04 | R$5.975,76 |

### 5.3 Add-ons (Opcionais)

| Add-on | Preço | Descrição |
|--------|-------|-----------|
| Agente adicional | R$49,90/mês | Por agente acima do limite do plano |
| Inbox adicional | R$29,90/mês | Por inbox acima do limite |
| Pacote de 500K tokens IA | R$99,90/mês | Tokens extras além da cota |
| Pacote de 2M tokens IA | R$299,90/mês | Para uso intenso de IA |
| 60 min de voz adicional | R$149,90/mês | Minutos de voz IA extras |
| Knowledge Base adicional | R$19,90/mês | Base de conhecimento extra |

---

## 6. Análise de Margem e Break-Even

### 6.1 Custo por Cliente (estimativa)

| Item | Essencial | Profissional | Business | Enterprise |
|------|-----------|-------------|----------|-----------|
| Infra rateada (10 clientes) | R$30,30 | R$30,30 | R$30,30 | R$30,30 |
| IA (tokens — custo bruto) | R$0,58 | R$8,70 | R$46,40 | R$145,00 |
| Voz (ElevenLabs/OpenAI) | R$0 | R$0 | R$87,00 | R$290,00 |
| Stripe (4,5% + R$0,39) | R$17,94 | R$35,94 | R$58,44 | R$112,44 |
| **Custo Total/cliente** | **R$48,82** | **R$74,94** | **R$222,14** | **R$577,74** |

### 6.2 Margem por Plano (mensal, por cliente)

| Plano | Receita | Custo | Margem Bruta | % Margem |
|-------|---------|-------|-------------|----------|
| 🟢 Essencial | R$389,90 | R$48,82 | **R$341,08** | **87,5%** |
| 🔵 Profissional | R$789,90 | R$74,94 | **R$714,96** | **90,5%** |
| 🟡 Business | R$1.289,90 | R$222,14 | **R$1.067,76** | **82,8%** |
| 🔴 Enterprise | R$2.489,90 | R$577,74 | **R$1.912,16** | **76,8%** |

> **Margem saudável em todos os planos.** O principal risco é voz IA no Business/Enterprise, que pode ter picos de uso.

### 6.3 Cenários de Break-Even (custos fixos = R$303/mês)

| Cenário | Nº de Clientes | Receita Total | Custo Var. Total | Custo Fixo | Lucro |
|---------|---------------|--------------|------------------|-----------|-------|
| Só Essencial | 1 | R$389,90 | R$48,82 | R$303,00 | **R$38,08** |
| Só Essencial | 5 | R$1.949,50 | R$244,10 | R$303,00 | **R$1.402,40** |
| Mix (2E + 2P + 1B) | 5 | R$3.649,50 | R$375,66 | R$303,00 | **R$2.970,84** |
| Mix (5E + 3P + 2B) | 10 | R$6.899,10 | R$913,66 | R$303,00 | **R$5.682,44** |
| Escala (10E + 5P + 3B + 2Ent) | 20 | R$12.828,50 | R$2.418,84 | R$303,00* | **R$10.106,66** |

> *Com 20+ clientes, provavelmente será necessário upgrade de servidor (~R$500/mês) ou separação de serviços.

### 6.4 Projeção de Scaling de Infraestrutura

| Nº de Clientes | Servidor Recomendado | Custo Infra/mês |
|---------------|---------------------|-----------------|
| 1-15 | Hetzner CCX23 (4 vCPU, 16 GB) | R$270 |
| 15-40 | Hetzner CCX33 (8 vCPU, 32 GB) | R$505 |
| 40-100 | Hetzner CCX43 (16 vCPU, 64 GB) | R$950 |
| 100+ | Cluster (múltiplos servidores) | R$2.000+ |

---

## 7. Plano de Implementação

### 7.1 Mudanças Necessárias no Código

#### 7.1.1 Atualizar Rake Task `saas_plans.rake`

```ruby
plans = [
  {
    name: 'Essencial',
    price_cents: 38_990,
    interval: 'month',
    agent_limit: 5,
    inbox_limit: 5,
    ai_tokens_monthly: 100_000,
    features: {
      basic_reports: true,
      editor_ai: true,
      audio_transcription: true,
      label_suggestion: true,
      webhooks: 1,
      automations: 5,
      macros: 10
    },
    active: true
  },
  {
    name: 'Profissional',
    price_cents: 78_990,
    interval: 'month',
    agent_limit: 15,
    inbox_limit: 20,
    ai_tokens_monthly: 500_000,
    features: {
      basic_reports: true, advanced_reports: true,
      editor_ai: true, copilot: true, assistant: true,
      summary: true, follow_up: true,
      audio_transcription: true, label_suggestion: true,
      ai_agents: true, ai_agents_limit: 1,
      knowledge_bases: 1, knowledge_docs: 50,
      agent_tools: 3,
      help_center: true, help_center_portals: 1, help_center_articles: 50,
      automations: 25, macros: 50, agent_bots: 2,
      campaigns: true, csv_export: true,
      webhooks: 5, ip_lookup: true,
      assignment_policies: true
    },
    active: true
  },
  {
    name: 'Business',
    price_cents: 128_990,
    interval: 'month',
    agent_limit: 40,
    inbox_limit: 60,
    ai_tokens_monthly: 2_000_000,
    features: {
      basic_reports: true, advanced_reports: true, full_reports: true,
      editor_ai: true, copilot: true, assistant: true,
      summary: true, follow_up: true, csat_analysis: true, captain_tasks: true,
      audio_transcription: true, label_suggestion: true,
      ai_agents: true, ai_agents_limit: 5,
      voice_agents: true, voice_agents_limit: 2, voice_minutes: 60,
      knowledge_bases: 10, knowledge_docs: 500,
      agent_tools: 20, workflows: true,
      help_center: true, help_center_portals: 3, help_center_articles: 500,
      help_center_embedding_search: true,
      automations: 100, macros: 200, agent_bots: 10,
      campaigns: true, whatsapp_campaigns: true, csv_export: true,
      sla: true, sla_policies: 3, audit_logs: true,
      custom_reply_email: true,
      webhooks: 20, ip_lookup: true,
      assignment_policies: true, advanced_assignment: true,
      advanced_search: true
    },
    active: true
  },
  {
    name: 'Enterprise',
    price_cents: 248_990,
    interval: 'month',
    agent_limit: 100,
    inbox_limit: 200,
    ai_tokens_monthly: 10_000_000,
    features: {
      basic_reports: true, advanced_reports: true, full_reports: true,
      editor_ai: true, copilot: true, assistant: true,
      summary: true, follow_up: true, csat_analysis: true, captain_tasks: true,
      audio_transcription: true, label_suggestion: true,
      ai_agents: true, ai_agents_limit: -1,
      voice_agents: true, voice_agents_limit: -1, voice_minutes: 300,
      knowledge_bases: -1, knowledge_docs: -1,
      agent_tools: -1, workflows: true,
      help_center: true, help_center_portals: -1, help_center_articles: -1,
      help_center_embedding_search: true,
      automations: -1, macros: -1, agent_bots: -1,
      campaigns: true, whatsapp_campaigns: true, csv_export: true,
      sla: true, sla_policies: -1, audit_logs: true,
      custom_reply_email: true, custom_reply_domain: true,
      disable_branding: true, white_label: true,
      saml_sso: true, custom_roles: true, companies: true,
      webhooks: -1, ip_lookup: true,
      assignment_policies: true, advanced_assignment: true,
      advanced_search: true,
      platform_api: true
    },
    active: true
  }
]
```

> **Nota:** `-1` indica ilimitado.

#### 7.1.2 Criar Planos Anuais

Adicionar variantes anuais de cada plano com `interval: 'year'` e preço calculado com 20% de desconto:

| Plano | Mensal (cents) | Anual (cents) |
|-------|---------------|--------------|
| Essencial | 38.990 | 374.304 |
| Profissional | 78.990 | 758.304 |
| Business | 128.990 | 1.238.304 |
| Enterprise | 248.990 | 2.390.304 |

#### 7.1.3 Re-sincronizar com Stripe

```bash
# Limpar IDs antigos do Stripe (opcional — ou arquivar produtos antigos no dashboard)
bundle exec rails runner "Saas::Plan.update_all(stripe_product_id: nil, stripe_price_id: nil)"

# Rodar seed com novos planos
bundle exec rake saas:seed_plans

# Sincronizar com Stripe (cria Products e Prices)
bundle exec rake saas:sync_plans_to_stripe
```

#### 7.1.4 Atualizar Frontend

- Atualizar labels de planos em `en.json` (i18n) com nomes em português
- Atualizar componentes de billing para mostrar os 4 novos planos
- Adicionar toggle Mensal/Anual na página de billing
- Mostrar economia anual em destaque

#### 7.1.5 Feature Flags por Plano

Implementar lógica no `Saas::Plan#features` para ativar/desativar feature flags conforme o plano da conta. Usar `before_action` nos controllers para verificar:

```ruby
# Em controllers que precisam de verificação de feature
before_action :require_feature!

def require_feature!(feature_name)
  plan = current_account.subscription&.plan
  unless plan&.features&.dig(feature_name.to_s)
    render json: { error: 'Recurso não disponível no seu plano' }, status: :forbidden
  end
end
```

---

## Apêndice A — Comparação com Concorrentes Brasileiros

| Plataforma | Plano Básico | IA Incluída | Canais | Voz IA |
|-----------|-------------|-------------|--------|--------|
| **AirysChat** | R$389,90 | ✅ 100K tokens | 13 | ✅ (Business+) |
| **Zenvia** | ~R$500+ | Limitada | 5-7 | — |
| **Take Blip** | Sob consulta | Add-on | 6-8 | Limitada |
| **RD Station Conversas** | ~R$359+ | Limitada | 3-4 | — |
| **Octadesk** | ~R$249+ | Básica | 5-6 | — |
| **Hubspot Service Hub** | ~R$800+ (USD) | Add-on | 4-5 | — |

**Diferenciais AirysChat:**
1. **19 modelos de IA** inclusos (OpenAI, Anthropic, Google, ElevenLabs)
2. **AI Agent Builder** com workflow visual — único no mercado brasileiro
3. **Voz IA** com OpenAI Realtime e ElevenLabs — inovação
4. **13 canais** nativos (mais que qualquer concorrente brasileiro)
5. **RAG + Knowledge Base** — IA contextualizada para cada negócio
6. **Preço competitivo** com muito mais funcionalidade

---

## Apêndice B — Glossário de Termos

| Termo | Significado |
|-------|-----------|
| **Token** | Unidade de texto processada pela IA (~4 caracteres = 1 token) |
| **RAG** | Retrieval-Augmented Generation — IA que consulta base de conhecimento |
| **LLM** | Large Language Model — modelo de linguagem de IA |
| **TTS** | Text-to-Speech — conversão de texto em fala |
| **STT** | Speech-to-Text — transcrição de fala em texto |
| **Realtime** | Processamento de voz em tempo real (conversa ao vivo com IA) |
| **Webhook** | Notificação HTTP enviada quando um evento ocorre |
| **Inbox** | Caixa de entrada conectada a um canal de comunicação |
| **SLA** | Service Level Agreement — acordo de nível de serviço |
| **CSAT** | Customer Satisfaction — pesquisa de satisfação do cliente |
| **SSO** | Single Sign-On — login único integrado |
| **2FA** | Two-Factor Authentication — autenticação em dois fatores |

---

## Apêndice C — Resumo Executivo

### Para investidores / decisores:

- **Mercado**: Atendimento ao cliente + IA conversacional no Brasil
- **Ticket médio**: R$389,90 — R$2.489,90/mês
- **Margem bruta**: 77% — 90% por cliente
- **Break-even**: 1 cliente (infra dedicada) ou 0 clientes adicionais com infra compartilhada
- **Custo fixo mensal**: ~R$303 (Hetzner + SMTP + domínio)
- **Diferencial**: Plataforma mais completa do mercado brasileiro com IA generativa embarcada
- **Meta Ano 1**: 20-50 clientes → MRR R$10K — R$30K
- **Meta Ano 2**: 100+ clientes → MRR R$50K+

### Riscos e Mitigações:

| Risco | Probabilidade | Mitigação |
|-------|-------------|-----------|
| Custo de IA disparar | Média | Limites de tokens por plano, credit_multiplier, fallback para modelos baratos |
| Uso excessivo de voz | Alta | Limite de minutos por plano, cobrança extra por add-on |
| Poucos clientes iniciais | Alta | Preço mínimo cobre infra com 1 cliente, marketing agressivo |
| Concorrência de preço | Baixa | Funcionalidades exclusivas (Agent Builder, voz IA) justificam premium |
| Aumento do dólar | Média | Margem alta absorve flutuações de até 30% |
