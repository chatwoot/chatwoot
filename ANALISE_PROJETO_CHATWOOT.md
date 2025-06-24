# Análise Completa do Projeto Chatwoot

Análise detalhada da arquitetura, funcionalidades e pontos de customização do Chatwoot.

## 🏗️ Arquitetura Geral

### Stack Tecnológico
- **Backend:** Ruby on Rails 7.1+ com Ruby 3.4.4
- **Frontend:** Vue.js 3.5+ com Vite
- **Banco de Dados:** PostgreSQL 13+ com Redis para cache/jobs
- **Jobs/Queue:** Sidekiq para processamento em background
- **Realtime:** Action Cable (WebSockets) para comunicação em tempo real
- **Assets:** Vite para build e bundling
- **Testes:** RSpec (Ruby) + Vitest (JavaScript)

### Estrutura Multi-Tenant
```ruby
# Model Account - Tenant principal
class Account < ApplicationRecord
  has_many :users, through: :account_users
  has_many :conversations, :contacts, :inboxes, :teams
  # Cada conta é um tenant isolado
end
```

## 📊 Principais Entidades e Relacionamentos

### Core Models
```
Account (Tenant)
├── Users (Agents/Admins)
├── Contacts (Clientes)
├── Inboxes (Canais de comunicação)
├── Conversations (Conversas)
│   └── Messages (Mensagens)
├── Teams (Equipes)
├── Labels (Etiquetas)
└── Custom Attributes (Atributos customizados)
```

### Modelo de Conversation (Central)
- **Status:** open, resolved, pending, snoozed
- **Priority:** low, medium, high, urgent
- **Assignee:** Agente responsável
- **Team:** Equipe responsável
- **Contact:** Cliente da conversa
- **Inbox:** Canal origem

### Modelo de Message
- **Message Types:** incoming, outgoing, activity, template
- **Content Types:** text, cards, form, email, sticker, etc.
- **Status:** sent, delivered, read, failed
- **Attachments:** Suporte a múltiplos anexos

## 🎯 Funcionalidades Principais

### 1. Gerenciamento de Conversas
- **Status Management:** Abertura, resolução, pendência
- **Assignment:** Auto e manual para agentes/equipes
- **Priority System:** 4 níveis de prioridade
- **Labels:** Sistema de etiquetagem flexível
- **Notes:** Notas internas privadas
- **Mentions:** Sistema de @menções

### 2. Canais de Comunicação (Inboxes)
- **Website Widget:** Chat web embutido
- **Email:** Integração completa com email
- **Facebook/Instagram:** Messenger e DMs
- **WhatsApp Business API**
- **Twitter/X:** DMs e menções
- **Telegram:** Bot integration
- **SMS:** Via Twilio
- **API Channel:** Integração customizada

### 3. Sistema de Agentes e Permissões
```yaml
Roles:
  - Agent: Acesso básico a conversas
  - Administrator: Gerenciamento completo
  - Custom Roles: Permissões granulares (Premium)
```

### 4. Automações e Bots
- **Automation Rules:** Regras baseadas em condições
- **Macros:** Ações pré-definidas
- **Agent Bots:** Integração com bots (Dialogflow, etc.)
- **Captain (AI):** Sistema de IA integrado (Premium)

### 5. Help Center
- **Articles:** Base de conhecimento
- **Categories:** Organização hierárquica
- **Portals:** Múltiplos portais por conta
- **Search:** Busca full-text

### 6. Relatórios e Analytics
- **Conversation Reports:** Métricas de conversas
- **Agent Reports:** Performance dos agentes
- **CSAT:** Pesquisas de satisfação
- **Custom Reports:** Relatórios personalizados

### 7. Integrações
- **Webhooks:** Eventos customizados
- **Slack:** Gerenciamento via Slack
- **Google Translate:** Tradução automática
- **Linear:** Criação de tickets
- **Shopify:** Integração e-commerce

## 🎨 Frontend Architecture (Vue.js)

### Estrutura do Dashboard
```
app/javascript/dashboard/
├── components/          # Componentes reutilizáveis
├── routes/             # Configuração de rotas
├── store/              # Vuex/Pinia stores
├── api/                # Clients da API
├── i18n/               # Internacionalização
├── mixins/             # Mixins compartilhados
└── constants/          # Constantes da aplicação
```

### Principais Componentes
- **ChatList:** Lista de conversas
- **ConversationView:** Interface de conversa
- **ContactPanel:** Painel de informações do contato
- **Sidebar:** Navegação principal
- **Settings:** Configurações da conta

## 🔧 Pontos de Customização Identificados

### 1. **Interface do Usuario (High Impact)**
```vue
<!-- Componentes facilmente customizáveis -->
app/javascript/dashboard/components/
├── layout/             # Layout principal
├── widgets/            # Widgets do dashboard
├── app/                # Componentes de app
└── ui/                 # Componentes de UI base
```

**Oportunidades:**
- Personalização de cores e temas
- Logo e branding customizado
- Layout de dashboard personalizado
- Widgets específicos da operação

### 2. **Funcionalidades de Negócio (Medium Impact)**
```ruby
# Extensões via Services e Jobs
app/services/           # Lógica de negócio
app/jobs/              # Processamento background
app/presenters/        # Formatação de dados
```

**Oportunidades:**
- Workflows customizados de atendimento
- Integrações com sistemas internos
- Automações específicas
- Relatórios personalizados

### 3. **API Extensions (High Impact)**
```ruby
# Rotas customizadas
namespace :api, defaults: { format: 'json' } do
  namespace :v1 do
    # Adicionar endpoints customizados aqui
  end
end
```

**Oportunidades:**
- Endpoints para integrações internas
- Webhooks customizados
- Métricas específicas
- Sincronização de dados

### 4. **Database Customizations (Low-Medium Impact)**
```ruby
# Custom attributes já disponíveis
class CustomAttributeDefinition < ApplicationRecord
  # Sistema flexível para campos customizados
end
```

**Oportunidades:**
- Campos específicos para contacts/conversations
- Metadados customizados
- Integrações com CRM externo

## 🎛️ Feature Flags Disponíveis

### Features Ativas por Padrão
- `inbound_emails`, `help_center`, `agent_bots`
- `macros`, `automations`, `labels`
- `campaigns`, `reports`, `crm`

### Features Premium/Configuráveis
- `disable_branding` - Remoção da marca Chatwoot
- `audit_logs` - Logs de auditoria
- `sla` - Service Level Agreements
- `captain_integration` - IA integrada
- `custom_roles` - Permissões granulares

## 🔄 Fluxos de Dados Principais

### 1. Fluxo de Conversa
```
Contact → Inbox → Conversation → Messages
                ↓
           Assignment (Agent/Team)
                ↓
           Actions (Reply, Resolve, Label)
```

### 2. Fluxo de Automação
```
Event Trigger → Automation Rule → Actions
                ↓
         (Label, Assignment, Webhook)
```

### 3. Fluxo Real-time
```
Action → Rails → ActionCable → Frontend Update
         ↓
     Background Jobs (Sidekiq)
```

## 💡 Recomendações para Customização

### 1. **Prioridade Alta - Quick Wins**
- **Branding:** Logo, cores, favicon customizados
- **Dashboard Widgets:** Métricas específicas da operação
- **Email Templates:** Templates personalizados
- **Canned Responses:** Respostas padrão da empresa

### 2. **Prioridade Média - Features Específicas**
- **Integração CRM:** Sincronização com sistema interno
- **Workflows Customizados:** Fluxos de atendimento específicos
- **Relatórios Personalizados:** KPIs da operação
- **Automações Avançadas:** Regras de negócio específicas

### 3. **Prioridade Baixa - Customizações Avançadas**
- **Novos Canais:** Integrações com plataformas específicas
- **ML/AI Personalizado:** Algoritmos de roteamento
- **Dashboards Executivos:** Visões estratégicas
- **APIs Específicas:** Endpoints para ferramentas internas

## 📁 Estrutura Recomendada para Customizações

```
# Organização sugerida para o fork
app/
├── customizations/          # Pasta para customizações
│   ├── services/           # Services específicos
│   ├── controllers/        # Controllers customizados
│   ├── models/             # Extensions de models
│   └── jobs/               # Jobs específicos
├── javascript/
│   └── dashboard/
│       └── customizations/ # Componentes customizados
└── views/
    └── customizations/     # Views customizadas
```

## 🚀 Próximos Passos Sugeridos

1. **Setup Completo:** Seguir `SETUP_DESENVOLVIMENTO.md`
2. **Branding Inicial:** Customizar logo e cores
3. **Análise de Requisitos:** Mapear necessidades específicas
4. **Priorização:** Definir roadmap de customizações
5. **Implementação Iterativa:** Desenvolver por sprints
6. **Testes e Validação:** Garantir qualidade das modificações

---

**Esta análise fornece a base para entender completamente o Chatwoot e identificar os melhores pontos para suas customizações específicas.** 