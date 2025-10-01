# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

# GP Bikes AI Assistant

## 📋 Resumen del Proyecto

**GP Bikes AI Assistant** es una plataforma de automatización conversacional impulsada por IA, construida sobre Chatwoot para ventas de motocicletas Yamaha y servicio al cliente en Colombia. El sistema utiliza 8 trabajadores de IA especializados para automatizar el 80% de las conversaciones de WhatsApp, desde la calificación de leads hasta el soporte post-venta.

**Objetivo de Negocio:** Automatizar calificación de leads, recomendaciones de productos, programación de servicios y financiamiento para GP Bikes (distribuidor Yamaha) con transferencia perfecta a agentes humanos cuando sea necesario.

---

## 🎯 Project Overview

**GP Bikes AI Assistant** is an AI-powered conversational automation platform built on Chatwoot for Yamaha motorcycle sales and customer service in Colombia. The system uses 8 specialized AI workers to automate 80% of WhatsApp conversations, from lead qualification to post-sale support.

**Business Goal:** Automate lead qualification, product recommendations, service scheduling, and financing for GP Bikes (Yamaha distributor) with seamless handoff to human agents when needed.

**Key Features:**
- Real-time WhatsApp conversation handling
- Intelligent lead scoring (1-10) with automatic routing
- CRM auto-population from conversations
- Multi-tenant architecture (Yamaha AI Network ready)
- Memory-persistent AI agents
- Service scheduling integration
- Financing calculation and approval

---

## 🛠️ Tech Stack

### Backend
- **Ruby**: 3.3.0 (use `rbenv` or `rvm`)
- **Rails**: 7.2.0
- **PostgreSQL**: 16.x (primary database)
- **Redis**: 7.2.x (cache + Sidekiq jobs)
- **Sidekiq**: Background job processing

### AI/ML Layer
- **OpenAI API**: GPT-4 Turbo (primary model)
- **Alternative**: Claude Sonnet 4.5 (fallback/testing)
- **ruby-openai**: ~> 6.3.0
- **tiktoken_ruby**: ~> 0.0.7 (token counting)

### Frontend
- **Vue.js**: 3.4.x (Composition API + `<script setup>`)
- **TypeScript**: 5.2.x
- **Vite**: 5.x (build tool)
- **TailwindCSS**: 3.4.x (styling)
- **Pinia**: 2.x (state management)

### Infrastructure
- **Docker**: 24.x + Docker Compose
- **Nginx**: 1.25.x (reverse proxy)
- **Railway/Render**: Initial deployment
- **AWS/DigitalOcean**: Production scaling

### Testing
- **RSpec**: 3.12.x (Ruby tests)
- **FactoryBot**: Test data
- **VCR**: OpenAI API mocking
- **Capybara**: E2E tests
- **SimpleCov**: Coverage reports (target: 90%+)

---

## 👥 Agentes Disponibles

Este proyecto utiliza 7 agentes especializados de Claude Code para diferentes áreas:

### 1. **Bolívar** (@backend-ai-workers-bolivar) - Backend AI Workers Expert
**Especialidad:** Ruby on Rails, AI Workers, OpenAI Integration
- Desarrollo e implementación de AI Workers en `app/services/ai_workers/`
- Integración con OpenAI API (GPT-4) con manejo robusto de errores
- Testing con RSpec + VCR cassettes
- Gestión de custom attributes de Chatwoot
- Background jobs con Sidekiq

**Cuándo usarlo:**
```bash
# En Claude Code:
@backend-ai-workers-bolivar "Necesito crear un nuevo AI Worker para capturar el presupuesto del cliente"
@backend-ai-workers-bolivar "El LeadQualificationWorker no se está activando correctamente"
@backend-ai-workers-bolivar "Agrega tests con VCR para el BudgetCaptureWorker"
```

### 2. **Catalina** (@frontend-vue-catalina) - Frontend Vue.js Expert
**Especialidad:** Vue.js 3, TypeScript, TailwindCSS, Pinia
- Componentes Vue en `app/javascript/dashboard/components/gp_bikes/`
- Integración con API de Chatwoot
- Formateo de pesos colombianos (COP)
- Diseño responsive mobile-first
- Tests con Vue Test Utils

**Cuándo usarlo:**
```bash
@frontend-vue-catalina "Crea un componente MotorcycleCard con precios en COP"
@frontend-vue-catalina "Necesito una calculadora de financiamiento interactiva"
@frontend-vue-catalina "El ServiceCalendar debe ser responsive en móviles"
```

### 3. **Simón** (@chatwoot-rails-architect) - Chatwoot Architecture Expert
**Especialidad:** Arquitectura Chatwoot, Event System, Multi-tenancy
- Event listeners en `app/listeners/`
- Custom API controllers en `app/controllers/api/v1/`
- Modelos personalizados con asociaciones Chatwoot
- Webhooks y automation rules
- Platform API y multi-tenancy

**Cuándo usarlo:**
```bash
@chatwoot-rails-architect "Crea un listener para message_created que enrute a AI workers"
@chatwoot-rails-architect "Necesito endpoints REST para /api/v1/gp_bikes/motorcycles"
@chatwoot-rails-architect "Agrega el modelo ServiceAppointment con relaciones a Conversation"
```

### 4. **Jorge** (@devops-infrastructure-jorge) - DevOps & Infrastructure Expert
**Especialidad:** Docker, CI/CD, Monitoring, Cloud Deployment
- Docker y Docker Compose (multi-stage builds)
- GitHub Actions workflows
- PostgreSQL y Redis configuration
- Railway, AWS, DigitalOcean deployments
- Prometheus + Grafana monitoring

**Cuándo usarlo:**
```bash
@devops-infrastructure-jorge "Crea docker-compose.yml para desarrollo local"
@devops-infrastructure-jorge "Setup CI/CD con GitHub Actions para deploy en Railway"
@devops-infrastructure-jorge "Configura monitoring con Prometheus y Grafana"
```

### 5. **María** (@qa-testing-maria) - QA & Testing Expert
**Especialidad:** RSpec, VCR, FactoryBot, Capybara, Coverage
- Tests comprehensivos para AI Workers
- VCR cassettes para OpenAI mocks
- Factories para Contact, Conversation, Message
- Tests E2E con Capybara + JavaScript
- Cobertura 90%+ con SimpleCov

**Cuándo usarlo:**
```bash
@qa-testing-maria "Crea tests para el nuevo RecommendationWorker con VCR"
@qa-testing-maria "Necesito integration tests para conversation threading"
@qa-testing-maria "Agrega E2E tests para el dashboard de motos con Capybara"
```

### 6. **Daniela** (@product-owner-daniela) - Product Owner & Requirements Expert
**Especialidad:** Requirements, User Stories, Conversation Flows, KPIs
- Definición de acceptance criteria
- User stories en español
- Diseño de flujos conversacionales (Mermaid)
- KPIs y métricas (lead score accuracy, handoff rate, automation %)
- A/B testing para prompts

**Cuándo usarlo:**
```bash
@product-owner-daniela "Define los requirements para un worker de calificación de leads"
@product-owner-daniela "¿Qué KPIs debemos medir para el WhatsApp bot?"
@product-owner-daniela "Valida que este prompt cumpla con los objetivos de negocio"
```

### 7. **Carlos** (@security-auditor-carlos) - Security Auditor Expert
**Especialidad:** OWASP Top 10, API Security, GDPR/LOPD Compliance
- Auditoría de vulnerabilidades (SQL injection, XSS, CSRF)
- Validación de secrets management
- Rate limiting y API security
- Input sanitization
- Encriptación de datos sensibles
- Compliance GDPR y LOPD Colombia

**Cuándo usarlo:**
```bash
@security-auditor-carlos "Audita el nuevo endpoint POST /api/users"
@security-auditor-carlos "Revisa la integración con OpenAI por seguridad"
@security-auditor-carlos "Verifica que los custom_attributes estén encriptados"
```

---

## 💬 Cómo Usar los Agentes

### En Claude Code (Interfaz CLI):

```bash
# Sintaxis básica
@nombre-agente "Tu pregunta o tarea específica"

# Ejemplos reales
@backend-ai-workers-bolivar "Implementa el GreetingWorker que capture nombre y interés general"

@frontend-vue-catalina "Crea LeadScoreDisplay.vue con visualización de score 1-10 y color coding"

@chatwoot-rails-architect "Diseña el ConversationRouter que distribuya mensajes a los 8 workers"

@devops-infrastructure-jorge "Setup completo de Docker con PostgreSQL 16, Redis 7 y hot-reload"

@qa-testing-maria "Tests para LeadQualificationWorker incluyendo edge cases y VCR cassettes"

@product-owner-daniela "Define user story para programación de test rides con acceptance criteria"

@security-auditor-carlos "Auditoría completa del sistema antes de deploy a producción"
```

### Múltiples Agentes (Flujo Completo):

```bash
# Paso 1: Definir requerimientos
@product-owner-daniela "User story para FinancingAgent que calcule cuotas"

# Paso 2: Implementar backend
@backend-ai-workers-bolivar "Implementa FinancingAgent según user story de Daniela"

# Paso 3: Crear frontend
@frontend-vue-catalina "Crea FinancingCalculator.vue que llame al FinancingAgent"

# Paso 4: Testing
@qa-testing-maria "Tests completos para FinancingAgent y FinancingCalculator"

# Paso 5: Seguridad
@security-auditor-carlos "Audita FinancingAgent antes de producción"

# Paso 6: Deploy
@devops-infrastructure-jorge "Deploy FinancingAgent a staging en Railway"
```

---

## 📦 Repository Strategy

### Base Repository Decision

**Selected:** Fork de `github.com/chatwoot/chatwoot` v4.6.0+
**Complementary:** SDK `github.com/chatwoot/ai-agents` como gem externo

### Architectural Approach

**Customization Pattern:**
```
GP Bikes AI Assistant (Fork de chatwoot/chatwoot)
├── Chatwoot Core (NO tocar directamente)
│   ├── app/models/contact.rb
│   ├── app/models/conversation.rb
│   └── app/controllers/api/v1/*
│
└── GP Bikes Customizations (Namespaces separados)
    ├── app/services/ai_workers/          # 8 AI Workers
    ├── app/models/gp_bikes/              # Custom models
    ├── app/models/concerns/              # Extensions vía concerns
    ├── app/listeners/                    # Event listeners
    ├── app/controllers/api/v1/gp_bikes/ # Custom endpoints
    └── config/ai_workers/                # Configuration YAML
```

**Key Principles:**

1. **Extend, Don't Modify:**
   - Use Ruby Concerns to extend Chatwoot models
   - Never edit Chatwoot core files directly
   - Single-line includes in core files when absolutely necessary

   ```ruby
   # ✅ CORRECT: app/models/concerns/gp_bikes_contact_attributes.rb
   module GpBikesContactAttributes
     extend ActiveSupport::Concern
     # Custom logic here
   end

   # app/models/contact.rb (Chatwoot core - only 1 line added)
   class Contact < ApplicationRecord
     include GpBikesContactAttributes  # ← Single addition
   end
   ```

2. **Event-Driven Integration:**
   - Subscribe to Chatwoot events via listeners
   - Events: `message_created`, `conversation_updated`, `conversation_status_changed`
   - Route messages to appropriate AI workers

   ```ruby
   # app/listeners/gp_bikes_message_listener.rb
   class GpBikesMessageListener < BaseListener
     def message_created(event)
       conversation = event.data[:message].conversation
       AiWorkers::ConversationRouter.new(conversation).route
     end
   end
   ```

3. **Upstream Synchronization:**
   - Monthly rebase from `chatwoot/chatwoot` upstream
   - Branch strategy: `gp-bikes-main` (development), `gp-bikes-production` (stable)
   - Test suite detects breaking changes from upstream

### Why This Architecture?

**Advantages:**
- ✅ Full control over AI worker implementation
- ✅ Direct access to Chatwoot event system
- ✅ Native WhatsApp Business API integration
- ✅ Multi-tenant architecture (Platform API) already implemented
- ✅ 100% stack alignment (Rails 7.2, Vue 3, PostgreSQL 16)
- ✅ Active community (305 contributors, monthly releases)

**Rejected Alternatives:**

❌ **Plugin/External Integration:**
- Limited customization capabilities
- API latency issues
- Cannot access internal events (message_created)
- Doesn't meet <2s response time requirement

❌ **Separate Frontend + Chatwoot Backend:**
- Logic duplication (auth, conversations)
- 2x operational complexity
- Larger security surface
- 3x development time

### Integration with ai-agents SDK

Use `chatwoot/ai-agents` gem for **agent orchestration**:

```ruby
# Gemfile
gem 'ai_agents', git: 'https://github.com/chatwoot/ai-agents'

# lib/ai_workers/agent_orchestrator.rb
class AgentOrchestrator
  def initialize(conversation)
    @conversation = conversation
    @agents = {
      lead_qualification: AIAgents::Agent.new(
        instructions: LeadQualificationWorker::SYSTEM_PROMPT,
        tools: [capture_lead_tool, score_lead_tool],
        handoff_to: [:product_catalog, :human_agent]
      ),
      product_catalog: AIAgents::Agent.new(
        instructions: ProductCatalogWorker::SYSTEM_PROMPT,
        tools: [search_motorcycles_tool],
        handoff_to: [:financing, :human_agent]
      )
      # ... 6 more agents
    }
  end
end
```

**Benefits of SDK:**
- Automatic handoff management between workers
- Shared context without data duplication
- Thread-safe for concurrent conversations
- Built-in conversation state serialization

---

## 📁 Project Structure

```
gp-bikes-ai/
├── .claude/                          # Claude Code configuration
│   ├── claude.md                     # This file
│   ├── agents/                       # AI agent documentation
│   │   ├── backend-ai-workers-bolivar.md
│   │   ├── frontend-vue-catalina.md
│   │   ├── chatwoot-expert-simon.md
│   │   ├── devops-infrastructure-jorge.md
│   │   ├── qa-testing-maria.md
│   │   ├── product-owner-daniela.md
│   │   └── security-auditor-carlos.md
│   └── commands/                     # Custom slash commands
│       ├── test-worker.md
│       └── deploy.md
│
├── app/
│   ├── services/
│   │   └── ai_workers/               # 👈 8 AI WORKERS - CORE LOGIC
│   │       ├── base_ai_worker.rb     # Base class for all workers
│   │       ├── lead_qualification_agent.rb
│   │       ├── product_catalog_agent.rb
│   │       ├── service_scheduling_agent.rb
│   │       ├── financing_agent.rb
│   │       ├── follow_up_agent.rb
│   │       ├── upselling_agent.rb
│   │       ├── post_sale_agent.rb
│   │       └── network_coordinator_agent.rb
│   │
│   ├── models/
│   │   ├── gp_bikes/                 # Custom models
│   │   │   ├── motorcycle.rb
│   │   │   ├── service_appointment.rb
│   │   │   ├── financing_application.rb
│   │   │   └── inventory.rb
│   │   └── concerns/
│   │       └── gp_bikes_contact_attributes.rb
│   │
│   ├── controllers/
│   │   └── api/v1/
│   │       └── gp_bikes_controller.rb  # Custom API endpoints
│   │
│   ├── jobs/
│   │   └── ai_workers/               # Background jobs
│   │       ├── follow_up_job.rb
│   │       ├── lead_scoring_job.rb
│   │       └── conversation_analyzer_job.rb
│   │
│   ├── listeners/                    # Chatwoot event listeners
│   │   └── gp_bikes_message_listener.rb
│   │
│   └── javascript/
│       └── dashboard/
│           └── components/
│               └── gp_bikes/         # Vue components
│                   ├── MotorcycleCard.vue
│                   ├── ServiceCalendar.vue
│                   ├── FinancingCalculator.vue
│                   ├── LeadScoreDisplay.vue
│                   └── WorkerStatusPanel.vue
│
├── config/
│   ├── ai_workers/                   # AI configuration
│   │   ├── agents.yml                # Worker settings
│   │   ├── prompts.yml               # System prompts
│   │   └── motorcycle_catalog.yml    # Yamaha catalog 2025
│   │
│   └── initializers/
│       └── gp_bikes.rb               # GP Bikes initialization
│
├── lib/
│   └── ai_workers/                   # Shared utilities
│       ├── openai_wrapper.rb
│       ├── memory_manager.rb
│       └── conversation_router.rb    # Worker routing logic
│
├── spec/                             # Tests
│   ├── services/ai_workers/
│   ├── models/gp_bikes/
│   ├── requests/api/v1/
│   ├── features/                     # E2E tests
│   ├── factories/
│   └── fixtures/
│       └── vcr_cassettes/            # OpenAI mocks
│
├── db/
│   └── migrate/                      # Database migrations
│
├── docker-compose.yml                # Local development
├── docker-compose.prod.yml           # Production
├── Dockerfile                        # Multi-stage build
├── .env.development                  # Local env vars (gitignored)
├── .env.production.example           # Production template
├── .cursorrules                      # Cursor IDE rules
└── README_GPBIKES.md                 # Project documentation
```

**Key Directories:**
- **app/services/ai_workers/**: All AI worker logic (NEVER modify without tests)
- **config/ai_workers/**: Configuration only, no code
- **spec/**: Must have 90%+ coverage for AI workers
- **app/javascript/dashboard/components/gp_bikes/**: Custom Vue components

---

## 🚀 Development Commands

### Setup
```bash
# Initial setup
bundle install
yarn install
rails db:create db:migrate db:seed

# With Docker
docker-compose up -d
docker-compose exec app bundle install
docker-compose exec app rails db:setup
```

### Development
```bash
# Start Rails server
rails server -b 0.0.0.0 -p 3000

# Start Sidekiq (in separate terminal)
bundle exec sidekiq

# Frontend build (watch mode)
yarn dev

# Docker
docker-compose up
docker-compose logs -f app
```

### Testing
```bash
# Run all tests
rspec

# Run specific worker test
rspec spec/services/ai_workers/lead_qualification_agent_spec.rb

# Run with coverage
COVERAGE=true rspec

# Run E2E tests (requires Chrome)
rspec spec/features/

# Lint Ruby
rubocop

# Lint JavaScript
yarn lint

# Type check
yarn typecheck
```

### Database
```bash
# Create migration
rails generate migration AddFieldToContacts field_name:string

# Run migrations
rails db:migrate

# Rollback
rails db:rollback

# Reset (DANGER: deletes all data)
rails db:reset

# Console
rails console
```

### AI Workers
```bash
# Test worker in console
rails c
> conversation = Conversation.last
> worker = AiWorkers::LeadQualificationAgent.new(conversation: conversation)
> worker.should_trigger?
> worker.process

# View worker logs
tail -f log/development.log | grep "AiWorkers"

# Test OpenAI connection
rails runner 'puts AiWorkers::BaseAiWorker.new(conversation: Conversation.first).send(:openai_client).models'
```

### Deployment
```bash
# Railway CLI
railway login
railway link
railway up

# Docker production build
docker build -t gp-bikes-ai:latest .
docker push gp-bikes-ai:latest

# Run migrations on production
railway run rails db:migrate
```

---

## 💻 Code Conventions

### Ruby/Rails

**Naming:**
- Files: `snake_case.rb`
- Classes: `PascalCase`
- Methods: `snake_case`
- Constants: `SCREAMING_SNAKE_CASE`

**Service Objects Pattern:**
```ruby
# ALWAYS use this pattern for AI workers
module AiWorkers
  class MyAgent < BaseAiWorker
    SYSTEM_PROMPT = <<~PROMPT
      System prompt here in Spanish (Colombia)
    PROMPT

    def should_trigger?
      # Activation logic (keywords, conditions)
    end

    def process
      # Main logic: call OpenAI, extract data, update memory, respond
    end

    private

    def helper_method
      # Private helpers
    end
  end
end
```

**AI Worker Rules:**
- ALWAYS inherit from `BaseAiWorker`
- System prompts MUST be in Spanish (Colombia dialect)
- ALWAYS use `call_openai` method from base class
- ALWAYS log important decisions: `Rails.logger.info "Worker: LeadQualification - Lead scored: 8"`
- ALWAYS rescue OpenAI errors: `rescue OpenAI::Error => e`
- ALWAYS update contact memory: `update_contact_memory(key: value)`
- NEVER hardcode prompts, use `config/ai_workers/prompts.yml`
- NEVER store sensitive data in logs

**Custom Attributes Schema:**
```ruby
# Always define schema in concerns/gp_bikes_contact_attributes.rb
SCHEMA = {
  lead_score: { type: :integer, range: 1..10 },
  presupuesto_cop: { type: :integer, min: 0 },
  modelo_interes: { type: :string }
}.freeze
```

**Testing:**
```ruby
# RSpec structure for workers
RSpec.describe AiWorkers::LeadQualificationAgent do
  let(:conversation) { create(:conversation) }
  let(:worker) { described_class.new(conversation: conversation) }

  describe '#should_trigger?' do
    # Test activation logic
  end

  describe '#process', :vcr do
    # Test with VCR cassettes
  end
end
```

### Vue.js / TypeScript

**Component Structure:**
```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'

// 1. Props (with TypeScript interface)
interface Props {
  motorcycleId: string
  showPrice?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  showPrice: true
})

// 2. Emits
const emit = defineEmits<{
  select: [id: string]
  close: []
}>()

// 3. State
const isLoading = ref(false)
const data = ref<Motorcycle | null>(null)

// 4. Computed
const formattedPrice = computed(() => {
  if (!data.value) return ''
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP'
  }).format(data.value.price)
})

// 5. Methods
const fetchData = async () => {
  isLoading.value = true
  // fetch logic
  isLoading.value = false
}

// 6. Lifecycle
onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="component-name">
    <!-- Use TailwindCSS classes only -->
  </div>
</template>

<style scoped>
/* Avoid custom CSS, use Tailwind utilities */
</style>
```

**Rules:**
- ALWAYS use Composition API with `<script setup>`
- ALWAYS define TypeScript interfaces for props
- Use TailwindCSS classes, NOT custom CSS
- ALWAYS format Colombian pesos: `es-CO` locale
- Component names: PascalCase (e.g., `MotorcycleCard.vue`)
- ALWAYS emit events for parent communication
- NEVER mutate props directly

### Git Workflow

**Branch Naming:**
```
feature/lead-qualification-agent
bugfix/openai-timeout-handling
hotfix/production-memory-leak
refactor/base-worker-optimization
```

**Commit Messages:**
```
feat(workers): Add FinancingAgent with credit calculation
fix(workers): Handle OpenAI timeout with exponential backoff
test(workers): Add VCR cassettes for ProductCatalogAgent
refactor(workers): Extract common OpenAI logic to base class
docs(readme): Update setup instructions for M1 Macs
```

**Workflow:**
1. Create feature branch from `develop`
2. Make changes with frequent commits
3. Run tests: `rspec spec/services/ai_workers/`
4. Run linter: `rubocop`
5. Push and create PR
6. Request review from @backend or @frontend team
7. After approval, merge to `develop`
8. Weekly deploys from `develop` to `main`

---

## 🎯 Roadmap & Development Phases

### PHASE 1: Foundation (Weeks 1-2) - CURRENT

**Goals:**
- ✅ Complete local development environment setup
- ✅ Implement BaseAiWorker with all core methods
- ✅ Create configuration system (agents.yml, prompts.yml)
- ✅ Establish testing patterns with RSpec + VCR

**Deliverables:**
- Docker Compose running PostgreSQL + Redis + Rails + Sidekiq
- BaseAiWorker class with 100% test coverage
- First VCR cassette recorded for OpenAI
- Documentation: Setup guide in README_GPBIKES.md

**Blockers to Resolve:**
- OpenAI API key provisioning
- WhatsApp Business API access
- Test data for Colombian motorcycle prices

### PHASE 2: Core AI Workers (Weeks 3-6)

**Priority Order:**

**Week 3-4: Lead Qualification + Product Catalog**
- ⬜ LeadQualificationAgent (captures: nombre, presupuesto, urgencia, experiencia)
- ⬜ Calculate lead_score algorithm (1-10)
- ⬜ ProductCatalogAgent (recommends motos based on profile)
- ⬜ Integration test: Lead → Catalog flow
- ⬜ Tests: 90%+ coverage for both workers

**Week 5-6: Service + Financing**
- ⬜ ServiceSchedulingAgent (agenda citas de taller)
- ⬜ FinancingAgent (calcula cuotas, pre-aprueba crédito)
- ⬜ Integration with taller API (webhook setup)
- ⬜ Integration with banco API (financing calculation)

**Success Metrics:**
- Lead qualification accuracy: 85%+
- Catalog recommendation relevance: 80%+
- Service scheduling success rate: 90%+

### PHASE 3: Advanced Workers (Weeks 7-9)

**Week 7-8:**
- ⬜ FollowUpAgent (automated daily follow-ups via Sidekiq)
- ⬜ UpsellingAgent (suggests accessories, insurance)
- ⬜ Integration with inventory API for real-time availability

**Week 9:**
- ⬜ PostSaleAgent (satisfaction surveys, maintenance reminders)
- ⬜ NetworkCoordinatorAgent (multi-tenant routing for Yamaha Network)

**Features:**
- Scheduled jobs with Sidekiq (follow-ups at 10am daily)
- WhatsApp template messages for proactive outreach
- Multi-tenant account creation via Platform API

### PHASE 4: Frontend Dashboard (Weeks 10-11)

**Components:**
- ⬜ WorkerStatusPanel.vue (live status of 8 workers)
- ⬜ LeadScoreDisplay.vue (visual score with color coding)
- ⬜ MotorcycleCard.vue (catalog with images + specs)
- ⬜ ServiceCalendar.vue (taller appointment scheduler)
- ⬜ FinancingCalculator.vue (interactive cuota calculator)

**API Endpoints:**
- GET /api/v1/gp_bikes/workers/status
- GET /api/v1/gp_bikes/motorcycles
- GET /api/v1/gp_bikes/leads?score_min=8
- POST /api/v1/gp_bikes/service_appointments

**Tests:**
- Vue Test Utils for all components
- Storybook for component documentation
- E2E tests with Capybara for critical flows

### PHASE 5: Deployment & Monitoring (Week 12)

**Infrastructure:**
- ⬜ Railway deployment (staging)
- ⬜ Production deployment (AWS/DO)
- ⬜ SSL certificates via Let's Encrypt
- ⬜ Domain: gpbikes-ai.com + admin.gpbikes-ai.com

**Monitoring:**
- ⬜ Sentry for error tracking
- ⬜ Datadog/New Relic for APM
- ⬜ Custom Grafana dashboard (worker performance)
- ⬜ PagerDuty for critical alerts

**Security:**
- ⬜ Rate limiting (100 req/min per IP)
- ⬜ API authentication with JWT
- ⬜ Secrets management with Vault or AWS Secrets Manager
- ⬜ Security audit with Carlos (@security-auditor-carlos)

**Go-Live Checklist:**
- ⬜ Load testing (1000 concurrent conversations)
- ⬜ Backup strategy (daily DB backups to S3)
- ⬜ Rollback plan documented
- ⬜ Team training session (2 hours)
- ⬜ Monitoring dashboards live
- ⬜ 24/7 on-call rotation established

### PHASE 6: Post-Launch Optimization (Ongoing)

**First Month:**
- Monitor worker performance metrics
- A/B test different system prompts
- Gather feedback from GP Bikes sales team
- Iterate on handoff threshold (currently score >= 8)

**Optimization Targets:**
- Response time: < 2 seconds
- Lead qualification accuracy: 90%+
- Automation rate: 80%+ (target)
- Customer satisfaction: 4.5/5 stars

**Scaling Plan:**
- Yamaha Network expansion (10 distributors by Month 6)
- Multi-language support (English for exports)
- Voice note transcription with Whisper API
- Image recognition for damage assessment (taller)

---

## 🚨 Do Not / Restrictions

### NEVER Do These Things

**Code:**
- ❌ NEVER commit API keys or secrets to git
- ❌ NEVER modify Chatwoot core files unless absolutely necessary
- ❌ NEVER use `eval()` or `instance_eval()` on user input
- ❌ NEVER deploy to production without tests passing
- ❌ NEVER hardcode motorcycle prices (use motorcycle_catalog.yml)
- ❌ NEVER write AI workers without inheriting from BaseAiWorker
- ❌ NEVER use `sleep()` in production code (use Sidekiq jobs)

**Files/Directories - Do NOT Touch:**
- `vendor/` (third-party gems)
- `node_modules/` (npm packages)
- `public/packs/` (compiled assets)
- `.git/` (git internals)
- `tmp/` (temporary files)
- `log/*.log` (log files, except for reading)
- Any file in `app/` that doesn't have `gp_bikes` in its path (Chatwoot core)

**Chatwoot Core - Modify Only If Necessary:**
- `app/models/contact.rb` (prefer using concerns)
- `app/models/conversation.rb` (prefer using listeners)
- `app/controllers/api/v1/conversations_controller.rb` (use custom controller instead)

**Data:**
- ❌ NEVER delete production data without explicit approval
- ❌ NEVER run `rails db:reset` or `rails db:drop` in production
- ❌ NEVER expose PII (Personally Identifiable Information) in logs
- ❌ NEVER store credit card numbers (use tokenization)

### Safe to Edit

**Full Edit Access:**
- `app/services/ai_workers/**/*`
- `app/models/gp_bikes/**/*`
- `app/controllers/api/v1/gp_bikes_controller.rb`
- `app/javascript/dashboard/components/gp_bikes/**/*`
- `config/ai_workers/**/*`
- `lib/ai_workers/**/*`
- `spec/**/*`
- `db/migrate/**/*` (new migrations only)
- `.claude/**/*`
- `README_GPBIKES.md`

---

## 🔧 Environment Setup

### Prerequisites
- Ruby 3.3.0 (via rbenv or rvm)
- Node.js 20.x (via nvm)
- PostgreSQL 16.x
- Redis 7.x
- Docker 24.x (optional but recommended)

### Environment Variables

**Required (.env.development):**
```bash
# OpenAI
OPENAI_API_KEY=sk-proj-...

# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/chatwoot_dev

# Redis
REDIS_URL=redis://localhost:6379

# Rails
SECRET_KEY_BASE=your-secret-key-base
RAILS_ENV=development
FRONTEND_URL=http://localhost:3000

# WhatsApp (get from Meta Business)
WHATSAPP_PHONE_NUMBER_ID=your-phone-id
WHATSAPP_ACCESS_TOKEN=your-access-token
WHATSAPP_WEBHOOK_VERIFY_TOKEN=your-verify-token
```

**Optional:**
```bash
# Claude API (alternative to OpenAI)
ANTHROPIC_API_KEY=sk-ant-...

# Monitoring
SENTRY_DSN=https://...
DATADOG_API_KEY=...

# Feature Flags
GP_BIKES_ENABLED=true
AI_WORKERS_ENABLED=true
```

### First-Time Setup
```bash
# 1. Clone and enter directory
git clone https://github.com/your-org/gp-bikes-ai.git
cd gp-bikes-ai

# 2. Install Ruby dependencies
bundle install

# 3. Install Node dependencies
yarn install

# 4. Setup database
rails db:create db:migrate db:seed

# 5. Create .env.development from template
cp .env.example .env.development
# Edit .env.development with your API keys

# 6. Test OpenAI connection
rails runner 'puts OpenAI::Client.new.models.map { |m| m["id"] }.join(", ")'

# 7. Start services
# Terminal 1: Rails
rails server

# Terminal 2: Sidekiq
bundle exec sidekiq

# Terminal 3: Frontend
yarn dev

# 8. Visit http://localhost:3000
```

### With Docker (Recommended)
```bash
# 1. Start all services
docker-compose up -d

# 2. Setup database
docker-compose exec app rails db:setup

# 3. View logs
docker-compose logs -f app

# 4. Access Rails console
docker-compose exec app rails console

# 5. Stop services
docker-compose down
```

---

## 📝 Instructions for Claude

### General Behavior

**When Writing Code:**
- ALWAYS check if a skill exists in `app/services/ai_workers/` before creating new workers
- ALWAYS write tests BEFORE implementing features (TDD)
- ALWAYS run `rspec` after making changes to workers
- ALWAYS use `Rails.logger.info` for important events
- PREFER service objects over fat models/controllers
- PREFER composition over inheritance (except for BaseAiWorker)

**When Using OpenAI:**
- ALWAYS use `call_openai` method from BaseAiWorker
- ALWAYS set temperature between 0.3-0.8 (0.3 for data extraction, 0.7 for conversations)
- ALWAYS handle timeouts with retry logic (max 3 attempts)
- ALWAYS log OpenAI requests: `Rails.logger.debug "OpenAI Request: #{prompt}"`
- NEVER exceed 500 max_tokens per request (cost optimization)

**When Modifying Prompts:**
- ALWAYS test prompt changes with at least 5 different user inputs
- ALWAYS update `config/ai_workers/prompts.yml`, NOT inline strings
- ALWAYS use Spanish (Colombia dialect): "moto" not "motocicleta", "plata" not "dinero"
- ALWAYS specify COP for prices: "$23.990.000 COP" not "$23990000"
- PREFER conversational tone over formal business language

**When Creating Vue Components:**
- ALWAYS use TypeScript with explicit interfaces
- ALWAYS use TailwindCSS classes (NO custom CSS)
- ALWAYS format prices with Colombian locale: `es-CO`
- PREFER functional components over class components
- PREFER Composition API over Options API

### Error Handling Patterns

```ruby
# OpenAI API calls
def call_openai_safely(prompt)
  retries = 0
  begin
    call_openai(system_prompt: SYSTEM_PROMPT, user_message: prompt)
  rescue OpenAI::Error => e
    retries += 1
    if retries < 3
      sleep(2 ** retries) # Exponential backoff
      retry
    else
      Rails.logger.error "OpenAI failed after 3 attempts: #{e.message}"
      send_message("Lo siento, hay un problema técnico. Un agente te contactará pronto.")
      nil
    end
  end
end
```

### Performance Guidelines

**Database Queries:**
- ALWAYS use `.includes()` to avoid N+1 queries
- ALWAYS add indexes for frequently queried fields
- NEVER use `.all` without a limit
- PREFER `.find_each` over `.each` for large datasets

**Background Jobs:**
- ALWAYS use Sidekiq for tasks > 1 second
- ALWAYS set appropriate queue priority
- NEVER run OpenAI calls in HTTP request cycle

**Caching:**
- Cache motorcycle catalog in Redis (expires: 1 day)
- Cache worker status in Redis (expires: 5 minutes)
- NEVER cache contact custom_attributes (always fresh)

### Security Guidelines
- ALWAYS sanitize user input before sending to OpenAI
- ALWAYS use parameterized queries (ActiveRecord handles this)
- ALWAYS validate webhook signatures from WhatsApp
- NEVER log sensitive data (phone numbers, prices discussed)
- ALWAYS use HTTPS in production

---

## 🎓 Learning Resources

### Chatwoot
- Official Docs: https://www.chatwoot.com/docs
- API Reference: https://www.chatwoot.com/developers/api
- GitHub: https://github.com/chatwoot/chatwoot

### OpenAI
- API Docs: https://platform.openai.com/docs
- Best Practices: https://platform.openai.com/docs/guides/prompt-engineering
- Pricing: https://openai.com/pricing

### Rails
- Guides: https://guides.rubyonrails.org
- API: https://api.rubyonrails.org
- Testing: https://rspec.info

### Vue.js
- Docs: https://vuejs.org
- Composition API: https://vuejs.org/guide/extras/composition-api-faq.html
- TypeScript: https://vuejs.org/guide/typescript/overview.html

---

## 📞 Team Contacts

**For Questions About:**
- Backend/AI Workers: @backend-ai-workers-bolivar
- Frontend/Vue: @frontend-vue-catalina
- Chatwoot Integration: @chatwoot-expert-simon
- DevOps/Deploy: @devops-infrastructure-jorge
- Testing/QA: @qa-testing-maria
- Product: @product-owner-daniela
- Security: @security-auditor-carlos

**Emergency Contacts:**
- Production Down: @devops-infrastructure-jorge
- Security Issue: @security-auditor-carlos
- OpenAI Budget Exceeded: @backend-ai-workers-bolivar

---

## 🚀 Quick Start Checklist

- ⬜ Ruby 3.3.0 installed
- ⬜ PostgreSQL 16 running
- ⬜ Redis 7 running
- ⬜ `bundle install` completed
- ⬜ `yarn install` completed
- ⬜ `.env.development` configured with OPENAI_API_KEY
- ⬜ `rails db:setup` completed
- ⬜ `rails server` running on port 3000
- ⬜ `bundle exec sidekiq` running
- ⬜ Can access http://localhost:3000
- ⬜ Tests passing: `rspec`
- ⬜ Read this entire CLAUDE.md file 😊

---

## 📊 Current Project Status

**Last Updated:** 30 de septiembre de 2025
**Phase:** PHASE 1 - Foundation (Week 1 of 12)

### ✅ Completed

**Planning & Architecture:**
- ✅ Project structure defined
- ✅ Tech stack selected (Rails 7.2, Vue 3, PostgreSQL 16, Redis 7, OpenAI GPT-4)
- ✅ CLAUDE.md created with comprehensive guidance
- ✅ 7 AI agents documented (Bolívar, Catalina, Simón, Jorge, María, Daniela, Carlos)
- ✅ **Repository strategy decided:** Fork `chatwoot/chatwoot` v4.6.0+
- ✅ **12-week roadmap designed** (README_ROADMAP.md)
- ✅ **8 user stories prioritized** (P0: 4, P1: 3, P2: 1)
- ✅ **KPIs framework established** (4 primary, 3 secondary)
- ✅ **4 conversation flows documented** (Mermaid diagrams)
- ✅ **Sprint 1 plan detailed** (380 hours, 65 hours user stories)

**Documentation Created:**
- ✅ `CLAUDE.md` - Architecture and development guide
- ✅ `README_ROADMAP.md` - Complete 12-week PRD
- ✅ `docs/user_stories/` - US-001, US-002, US-003 + README
- ✅ `docs/flows/` - Lead qualification, product recommendation, service scheduling, error handling
- ✅ `docs/kpis/metrics-framework.md` - Complete metrics system
- ✅ `docs/sprints/sprint-01-plan.md` - Detailed Sprint 1 breakdown

### 🔄 Ready to Start (Sprint 1 - Weeks 1-2)

**Next Sprint 1 Actions (1-12 de octubre):**

**Week 1 (Día 1-4):**
1. ⬜ Fork chatwoot/chatwoot v4.6.0 → `gpbikes/gp-bikes-ai`
2. ⬜ Setup Docker Compose (PostgreSQL 16 + Redis 7 + Rails + Sidekiq)
3. ⬜ Configure RSpec + FactoryBot + VCR
4. ⬜ Test OpenAI API connectivity
5. ⬜ Setup GitHub Actions CI/CD pipeline
6. ⬜ Security scan with Brakeman + bundle-audit

**Week 2 (Día 5-14):**
1. ⬜ Implement BaseAiWorker with all core methods
2. ⬜ Build OpenAI wrapper with retry logic
3. ⬜ Create memory manager for custom_attributes
4. ⬜ Implement ConversationRouter + Event Listener
5. ⬜ Build GreetingWorker (first functional AI worker)
6. ⬜ Write comprehensive tests (target: 90%+ coverage)
7. ⬜ Record VCR cassettes for OpenAI mocking
8. ⬜ Manual testing in local environment

### 🎯 Sprint 1 Goals

**Primary:**
- ✅ Infrastructure: `docker-compose up` works for entire team
- ✅ BaseAiWorker: 100% tested, documented, production-ready
- ✅ GreetingWorker: Responds automatically to first WhatsApp messages

**Metrics:**
- Coverage: >= 90%
- CI Pipeline: 100% green
- Response Time: <2 seconds (GreetingWorker)
- Team Capacity: 380 hours (65h user stories + 315h infra)

### 🚧 Current Blockers

**Critical (Resolve Week 1):**
- ⚠️ OpenAI API key needed (organization: GP Bikes)
- ⚠️ WhatsApp Business API access (tier: empresarial 10k/día)
- ⚠️ Repository provisioning (GitHub organization)

**Important (Resolve before Sprint 2):**
- ℹ️ Test motorcycle catalog data (25 modelos Yamaha 2025)
- ℹ️ Access to GP Bikes historical leads (for validation)
- ℹ️ Taller/workshop API documentation (if exists)

### 📅 Key Dates

- **Sprint 1 Start:** Lunes 1 de Octubre, 9am COT (Sprint Planning)
- **Daily Standups:** 9:00am COT (lunes-viernes)
- **Sprint 1 Review:** Viernes 12 de Octubre, 3pm COT
- **Sprint 1 Retrospective:** Viernes 12 de Octubre, 4:30pm COT
- **Sprint 2 Start:** Lunes 15 de Octubre

### 📚 Documentation Available

- [README_ROADMAP.md](./README_ROADMAP.md) - Complete 12-week plan
- [docs/user_stories/](./docs/user_stories/) - Prioritized user stories
- [docs/flows/](./docs/flows/) - Conversation flow diagrams
- [docs/kpis/](./docs/kpis/) - Metrics framework
- [docs/sprints/sprint-01-plan.md](./docs/sprints/sprint-01-plan.md) - Sprint 1 details

---

## 🚀 Próximos Pasos

### Fase 1: Fundación (Semanas 1-2) - ACTUAL
1. ✅ Estructura del proyecto definida
2. ✅ Stack técnico seleccionado
3. ✅ CLAUDE.md creado
4. ✅ Agentes documentados
5. ⬜ Setup docker-compose.yml con PostgreSQL 16 + Redis 7
6. ⬜ Crear BaseAiWorker con métodos core
7. ⬜ Primer VCR cassette grabado
8. ⬜ Tests RSpec configurados

### Fase 2: Core AI Workers (Semanas 3-6)
1. ⬜ LeadQualificationAgent (captura: nombre, presupuesto, urgencia)
2. ⬜ ProductCatalogAgent (recomienda motos según perfil)
3. ⬜ ServiceSchedulingAgent (agenda citas de taller)
4. ⬜ FinancingAgent (calcula cuotas, pre-aprueba crédito)
5. ⬜ Tests con 90%+ coverage

### Fase 3: Frontend Dashboard (Semanas 7-8)
1. ⬜ MotorcycleCard.vue (catálogo con precios COP)
2. ⬜ ServiceCalendar.vue (calendario de citas)
3. ⬜ FinancingCalculator.vue (calculadora interactiva)
4. ⬜ LeadScoreDisplay.vue (visualización de score)
5. ⬜ WorkerStatusPanel.vue (estado de 8 workers)

### Fase 4: Deployment (Semana 9)
1. ⬜ Railway deployment (staging)
2. ⬜ CI/CD con GitHub Actions
3. ⬜ Monitoring con Prometheus + Grafana
4. ⬜ Security audit completo
5. ⬜ Go-live a producción

---

**Remember:** This is a living document. Update it as the project evolves. When you discover a new pattern or convention, add it here so the whole team (and Claude) benefits! 🎯
