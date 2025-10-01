# GP Bikes AI Assistant - Product Roadmap

**Product Owner:** Daniela
**Versión:** 1.0
**Fecha:** 30 de septiembre de 2025
**Duración:** 12 semanas (3 meses)

---

## 📋 Resumen Ejecutivo

GP Bikes AI Assistant es una plataforma de automatización conversacional para WhatsApp que transformará la operación comercial de GP Bikes (distribuidor Yamaha en Colombia), **automatizando el 80% de las conversaciones de ventas** mediante 8 trabajadores de IA especializados con transferencia inteligente a agentes humanos.

### Objetivos de Negocio

| Métrica | Baseline | Meta Mes 1 | Meta Mes 3 | Meta Mes 6 |
|---------|----------|------------|------------|------------|
| Tasa de Automatización | 0% | 60% | 75% | **80%** |
| Precisión Lead Score | N/A | 80% | **85%** | 90% |
| Tasa de Handoff | 100% | 40% | 25% | **20%** |
| Tiempo de Respuesta | 15 min | 2 min | 1 min | **<30 seg** |
| Satisfacción Cliente | 3.5/5 | 4.0/5 | 4.3/5 | **4.5/5** |

---

## 📦 Decisión Arquitectónica

### Repositorio Seleccionado

**Base:** `github.com/chatwoot/chatwoot` v4.6.0+ (Fork)
**Complemento:** `github.com/chatwoot/ai-agents` (SDK Ruby para orquestación)

### ¿Por qué Fork de Chatwoot?

#### ✅ Ventajas

- **Control total** sobre personalizaciones profundas
- **Event system nativo** para AI Workers (message_created, conversation_updated)
- **WhatsApp Business API** ya integrado
- **Stack 100% alineado**: Rails 7.2, Vue 3, PostgreSQL 16, Redis 7
- **Multi-tenancy** implementado (Platform API)
- **Comunidad activa**: 305 contributors, 5,430 commits, releases mensuales
- **Custom attributes** perfecto para memory persistence

#### ❌ Alternativas Rechazadas

**Plugin/Integración Externa:**
- Limitaciones en personalización
- Latencia adicional (>2s)
- No accede a eventos internos críticos

**Frontend Custom + Chatwoot Backend Separado:**
- Duplicación de lógica (auth, conversations)
- 2x complejidad operacional
- 3x tiempo de desarrollo

### Estrategia de Customización

```
GP Bikes AI Assistant (Fork chatwoot/chatwoot)
│
├── Chatwoot Core (NO TOCAR)
│   ├── app/models/contact.rb
│   ├── app/models/conversation.rb
│   └── app/controllers/api/v1/*
│
└── GP Bikes Custom (Namespaces separados)
    ├── app/services/ai_workers/          # 8 AI Workers
    ├── app/models/gp_bikes/              # Custom models
    ├── app/models/concerns/              # Extensions vía Concerns
    ├── app/listeners/                    # Event listeners
    ├── app/controllers/api/v1/gp_bikes/ # Custom endpoints
    └── config/ai_workers/                # YAML configuration
```

**Principio Core:** Extender mediante Concerns, NO modificar archivos core directamente.

---

## 🗓️ Roadmap - 12 Semanas

### FASE 1: Fundación (Semanas 1-2)

**Objetivo:** Ambiente de desarrollo funcional + BaseAiWorker + Primer worker (GreetingWorker)

#### Semana 1: Infrastructure Setup

| Tarea | Owner | Horas |
|-------|-------|-------|
| Fork chatwoot/chatwoot v4.6.0 | Jorge | 2h |
| Docker Compose (PostgreSQL 16 + Redis 7) | Jorge | 4h |
| Setup RSpec + FactoryBot + VCR | María | 4h |
| OpenAI API integration (test) | Bolívar | 3h |
| GitHub Actions CI pipeline | Jorge | 4h |
| README_GPBIKES.md | Daniela | 2h |

**Total:** 22 horas

**Success Criteria:**
- ✅ `docker-compose up` levanta app en <2 minutos
- ✅ `rspec` ejecuta sin errores
- ✅ OpenAI API conectada exitosamente
- ✅ CI pipeline verde en GitHub Actions

#### Semana 2: BaseAiWorker + GreetingWorker

| Tarea | Owner | Horas |
|-------|-------|-------|
| BaseAiWorker con métodos core | Bolívar | 8h |
| OpenAI wrapper con retry logic | Bolívar | 4h |
| Memory manager (custom_attributes) | Bolívar | 6h |
| ConversationRouter (event listener) | Simón | 6h |
| Config system (agents.yml, prompts.yml) | Simón | 3h |
| GreetingWorker (primer worker funcional) | Bolívar | 5h |
| Tests RSpec + VCR cassettes | María | 8h |

**Total:** 43 horas

**Success Criteria:**
- ✅ BaseAiWorker 100% coverage
- ✅ GreetingWorker responde automáticamente a mensajes nuevos
- ✅ Memory persistence funciona (custom_attributes)
- ✅ VCR cassettes grabados

---

### FASE 2: Core AI Workers (Semanas 3-6)

#### Semana 3: LeadQualificationWorker

**Objetivo:** Calificación automática de leads con score 1-10

**Entregables:**
- LeadQualificationWorker con algoritmo de scoring
- Captura: presupuesto_cop, urgencia, experiencia
- Automation rule: handoff a agente si score >= 8
- Tests con 15+ escenarios
- Dashboard Vue: LeadScoreDisplay.vue

**Total:** 42 horas

**Algoritmo Lead Score:**

```
Score = (Presupuesto * 0.4) + (Urgencia * 0.35) + (Experiencia * 0.25)

Presupuesto (1-10):
  10: >= $30M COP (gama alta: MT-09, Ténéré 700)
  8-9: $20M-29M COP (gama media-alta: XTZ 250, FZ25)
  6-7: $10M-19M COP (gama media: FZ-16, XTZ 125)
  4-5: $5M-9M COP (gama entrada: Factor 150)
  1-3: < $5M COP (requiere financiamiento fuerte)

Urgencia (1-10):
  10: "Compro hoy/esta semana"
  8-9: "Este mes"
  6-7: "Próximos 2-3 meses"
  4-5: "Estoy mirando opciones"
  1-3: "Solo información"

Experiencia (1-10):
  10: Conductor experimentado con moto actual
  8-9: Tiene licencia, sin moto actual
  6-7: Tiene licencia en trámite
  4-5: No tiene licencia aún
  1-3: Primera vez, no sabe conducir
```

#### Semana 4: ProductCatalogWorker

**Objetivo:** Recomendaciones personalizadas de motos Yamaha

**Entregables:**
- ProductCatalogWorker
- motorcycle_catalog.yml (25 modelos Yamaha 2025)
- Modelo Motorcycle (ActiveRecord)
- API endpoint GET /api/v1/gp_bikes/motorcycles
- MotorcycleCard.vue (componente catálogo)

**Total:** 43 horas

**Catálogo Yamaha 2025:**
- 25 modelos completos con specs
- Categorías: naked_sport, enduro, touring, scooter, sport
- Datos: precio_cop, cilindraje, consumo, experiencia_requerida

#### Semana 5: ServiceSchedulingWorker

**Objetivo:** Agendamiento automático de citas de taller

**Entregables:**
- ServiceSchedulingWorker
- Modelo ServiceAppointment
- Integración con taller API (webhook)
- Calendario de disponibilidad
- ServiceCalendar.vue (UI calendario)

**Total:** 48 horas

#### Semana 6: FinancingWorker

**Objetivo:** Cálculo de cuotas y pre-aprobación de financiamiento

**Entregables:**
- FinancingWorker
- Modelo FinancingApplication
- Integración API bancaria (simulación)
- Cálculo de cuotas (TNA, plazo, cuota inicial)
- FinancingCalculator.vue (calculadora interactiva)

**Total:** 50 horas

**Parámetros Financieros:**
- TNA: 18% (configurable en agents.yml)
- Plazos: 12, 24, 36, 48 meses
- Validación: cuota/ingreso <= 30% (norma bancaria)

---

### FASE 3: Advanced Workers (Semanas 7-9)

#### Semana 7-8: FollowUpWorker + UpsellingWorker

**Objetivos:**
- Follow-ups automáticos diarios (Sidekiq scheduled job)
- Upselling de accesorios y seguros
- WhatsApp template messages

**Total:** 53 horas

#### Semana 9: PostSaleWorker + NetworkCoordinatorWorker

**Objetivos:**
- Encuestas NPS post-venta
- Recordatorios de mantenimiento automáticos
- Multi-tenant routing para Yamaha Network

**Total:** 54 horas

---

### FASE 4: Frontend Dashboard (Semanas 10-11)

#### Semana 10: Componentes Vue Core

**Entregables:**
- WorkerStatusPanel.vue (estado 8 workers en tiempo real)
- LeadScoreDisplay.vue (visualización score con color coding)
- ConversationTimeline.vue (línea de tiempo)
- Pinia stores (state management)

**Total:** 48 horas

#### Semana 11: Componentes Avanzados

**Entregables:**
- FinancingSimulator.vue (calculadora interactiva)
- MotorcycleComparison.vue (comparador lado a lado)
- LeadsDashboard.vue (tabla con filtros)
- Storybook setup + stories
- E2E tests con Capybara

**Total:** 48 horas

---

### FASE 5: Deployment & Monitoring (Semana 12)

#### Semana 12: Go-Live

**Entregables:**
- Railway staging deployment
- AWS/DigitalOcean production setup
- SSL certificates (Let's Encrypt)
- Sentry error tracking
- Grafana dashboards (8 workers)
- PagerDuty alerting
- Security audit completo (Carlos)
- Load testing (1000 concurrent users)
- Backup strategy (S3, diario)
- Team training (2h session)
- Rollback plan documentation

**Total:** 64 horas

**Go-Live Checklist:**

```
Pre-Launch (L-7 días):
  □ Todos los tests pasando (RSpec + E2E)
  □ Coverage >= 90%
  □ Security audit aprobado
  □ Load testing exitoso (1000 users)
  □ Staging tested por equipo GP Bikes (3 días)
  □ Rollback plan documentado y probado

Launch Day (L-Day):
  □ Deploy en horario valle (3am-5am COT)
  □ Smoke tests post-deploy (15 min)
  □ Monitoring dashboards verificados
  □ Equipo on-call disponible 24h
  □ WhatsApp productivo conectado

Post-Launch (L+1 a L+7):
  □ Monitoreo intensivo 24/7
  □ Daily stand-ups 9am
  □ Ajustes de prompts según métricas
```

---

## 📊 KPIs y Métricas

### KPIs Primarios (Monitoreo Daily)

#### 1. Tasa de Automatización

**Fórmula:**
```
Tasa Automatización = (Conversaciones 100% IA / Total Conversaciones) * 100
```

**Metas:**
- Mes 1: 60%
- Mes 3: 75%
- Mes 6: **80%**

#### 2. Precisión de Lead Score

**Fórmula:**
```
Precisión = (Leads correctamente clasificados / Total leads evaluados) * 100

Correcto si:
  - Score >= 8 Y convirtió en venta = TRUE
  - Score < 8 Y NO convirtió = TRUE
```

**Metas:**
- Mes 1: 80%
- Mes 3: **85%**
- Mes 6: 90%

#### 3. Tasa de Handoff

**Fórmula:**
```
Tasa Handoff = (Conversaciones transferidas / Total conversaciones) * 100
```

**Metas:**
- Mes 1: 40%
- Mes 3: 25%
- Mes 6: **20%**

#### 4. Tiempo de Respuesta

**SLA por Worker:**

| Worker | SLA Target | P95 | P99 |
|--------|------------|-----|-----|
| GreetingWorker | 2s | 3s | 5s |
| LeadQualificationWorker | 5s | 8s | 12s |
| ProductCatalogWorker | 8s | 12s | 20s |
| ServiceSchedulingWorker | 10s | 15s | 25s |
| FinancingWorker | 15s | 20s | 30s |

**Metas:**
- Mes 1: < 2 minutos
- Mes 3: < 1 minuto
- Mes 6: **< 30 segundos**

### KPIs Secundarios (Monitoreo Weekly)

#### 5. Tasa de Conversión Lead-a-Venta

**Baseline:** 15% (actual sin IA)
**Meta Mes 6:** 20% (incremento del 33%)

#### 6. NPS (Net Promoter Score)

**Fórmula:**
```
NPS = % Promotores (9-10) - % Detractores (0-6)
```

**Pregunta:** *"En una escala de 0 a 10, ¿qué tan probable es que recomiendes GP Bikes a un amigo?"*

**Metas:**
- Mes 1: 30
- Mes 3: 45
- Mes 6: **60**

#### 7. Costo por Lead Calificado

**Meta:** < $2,000 COP/lead (vs $8,000 COP manual)

### Dashboard Grafana - Estructura

**Panel 1: Overview (Última hora)**
```
┌─────────────────────────────────────────────┐
│ Conversaciones Activas: 47                  │
│ Tasa Automatización (24h): 78.3%            │
│ Tiempo Respuesta Avg: 4.2s                  │
│ Workers Activos: 8/8 ✅                      │
└─────────────────────────────────────────────┘
```

**Panel 2: Worker Performance (Tiempo real)**
```
Worker                  | Activo | Avg Response | Errors/h |
------------------------|--------|--------------|----------|
GreetingWorker         | ✅     | 1.8s         | 0        |
LeadQualificationWorker| ✅     | 4.5s         | 2        |
ProductCatalogWorker   | ✅     | 7.1s         | 1        |
ServiceSchedulingWorker| ✅     | 9.3s         | 0        |
FinancingWorker        | ✅     | 12.8s        | 3        |
```

**Panel 3: Lead Quality (Última semana)**
```
Score Distribution:
[████████████] 8-10 (32%)  ← Alta calidad
[██████████  ] 5-7  (41%)  ← Media
[█████       ] 1-4  (27%)  ← Baja

Conversión por Score:
  8-10: 45% converted ✅
  5-7:  18% converted
  1-4:  3% converted
```

---

## 🚨 Riesgos y Mitigación

### Matriz de Riesgos

```
IMPACTO
  │
C │  R-T3      R-O2      R-S1
R │  (Data     (Down-    (PII
Í │  Loss)     time)     Leak)
T │
I │
C │
O │
  │
A │  R-T1      R-N1      R-N2      R-O1
L │  (OpenAI   (Adop-    (Score    (WhatsApp
T │  Perf)     tion)     Acc)      Limit)
O │
  │
M │  R-T2      R-N3      R-O3      R-S2
E │  (Chat-    (Expec-   (Costs)   (Prompt
D │  woot)     tations)            Inject)
I │
O │
  │
  └────────────────────────────────────
     BAJA     MEDIA     ALTA
           PROBABILIDAD
```

### Riesgos Críticos (Alto Impacto)

#### R-S1: Exposición de Datos Personales (PII)
**Probabilidad:** Media | **Impacto:** Crítico

**Mitigación:**
- Log sanitization (redactar PII automáticamente)
- Encryption at rest (PostgreSQL TDE)
- Access control (RBAC estricto)
- Audits mensuales por Carlos

**Owner:** Carlos

#### R-N1: Baja Adopción por Equipo de Ventas
**Probabilidad:** Media | **Impacto:** Alto

**Mitigación:**
- Training sessions (2h onboarding + 1h semanal Q&A)
- Early wins (mostrar leads precisos en primera semana)
- Feedback loop (daily check-in primeras 2 semanas)
- Incentivos (bonus por conversión de leads IA-qualified)

**Owner:** Daniela

#### R-N2: Precisión de Lead Score Insuficiente (<80%)
**Probabilidad:** Media | **Impacto:** Alto

**Mitigación:**
- Iteración rápida (A/B testing de fórmulas semanales)
- Validation con histórico (500 leads pasados antes de launch)
- Human-in-the-loop (primeras 2 semanas, validación manual)
- ML futuro (si reglas no funcionan, modelo ML en Mes 4-6)

**Owner:** Daniela + Bolívar

#### R-O1: WhatsApp Business API Rate Limiting
**Probabilidad:** Media | **Impacto:** Alto

**Mitigación:**
- Tier upgrade (negociar tier empresarial 10k/día)
- Priorización (leads score >= 8 prioritarios en queue)
- Batching (agrupar follow-ups en horarios valle)
- Monitoring (alert si cerca del 80% del límite)

**Owner:** Jorge + Daniela

---

## 📝 User Stories Prioritizadas

### Must Have (Críticas - Sprint 1-6)

#### US-001: BaseAiWorker (Semana 2)
**Prioridad:** P0 - Bloqueante

```
Como desarrollador backend,
Quiero una clase base BaseAiWorker con métodos comunes,
Para implementar nuevos AI workers de forma consistente.

Acceptance Criteria:
- Métodos abstractos: should_trigger?, process
- call_openai con retry (3 intentos, exponential backoff)
- update_contact_memory para persistence
- send_message para respuestas
- Logging estructurado (Rails.logger)
- Tests 100% coverage
```

#### US-002: GreetingWorker (Semana 2)
**Prioridad:** P0 - Bloqueante

```
Como cliente nuevo en WhatsApp,
Quiero recibir saludo automático al iniciar conversación,
Para sentirme atendido inmediatamente.

Acceptance Criteria:
- Activación en primer mensaje (messages_count == 1)
- Respuesta < 2 segundos
- Mensaje: saludo + empresa + horarios
- Captura nombre si se menciona
- No se activa en mensajes subsecuentes
```

#### US-003: Lead Qualification (Semana 3)
**Prioridad:** P0 - Crítica

```
Como equipo de ventas,
Quiero calificación automática de leads con score 1-10,
Para enfocarme en leads de alto potencial (score >= 8).

Acceptance Criteria:
- Captura: presupuesto_cop, urgencia, experiencia
- Algoritmo: Presupuesto(40%) + Urgencia(35%) + Experiencia(25%)
- Score >= 8: asignación automática a agente
- Score < 8: continúa con ProductCatalogWorker
- Dashboard con color coding: Verde(8-10), Amarillo(5-7), Rojo(1-4)
- Precisión >= 85% (validar con histórico ventas)
```

Ver archivo completo de user stories en: [`docs/user_stories/`](./docs/user_stories/)

---

## 🎯 Sprint 1 - Plan Detallado (Semanas 1-2)

### Objetivo del Sprint

Establecer infraestructura base completa y primer AI Worker funcional (GreetingWorker) con tests automatizados.

### Team Capacity

| Role | Nombre | Disponibilidad | Horas Sprint |
|------|--------|----------------|--------------|
| Backend | Bolívar | 100% | 80h |
| Frontend | Catalina | 50% | 40h |
| Architect | Simón | 100% | 80h |
| DevOps | Jorge | 75% | 60h |
| QA | María | 100% | 80h |
| Product Owner | Daniela | 25% | 20h |
| Security | Carlos | 25% | 20h |

**Total Capacity:** 380 horas

### Sprint Backlog Detallado

Ver plan completo en: [`docs/sprints/sprint-01-plan.md`](./docs/sprints/sprint-01-plan.md)

### Definition of Done (Sprint 1)

**Infraestructura:**
- [ ] `docker-compose up` levanta ambiente completo
- [ ] CI pipeline verde en GitHub Actions
- [ ] Documentación setup validada por equipo

**Código:**
- [ ] BaseAiWorker 100% testeado y funcional
- [ ] GreetingWorker responde automáticamente
- [ ] ConversationRouter rutea correctamente
- [ ] Memory persistence funcionando

**Tests:**
- [ ] RSpec coverage >= 90%
- [ ] VCR cassettes grabados
- [ ] Integration test pasando

**Calidad:**
- [ ] Rubocop sin offenses críticos
- [ ] Security scan sin vulnerabilidades altas
- [ ] Logs estructurados y legibles

---

## 📞 Contactos y Recursos

### Equipo

**Para Consultas:**
- Backend/AI Workers: @backend-ai-workers-bolivar
- Frontend/Vue: @frontend-vue-catalina
- Chatwoot Integration: @chatwoot-rails-architect
- DevOps/Deploy: @devops-infrastructure-jorge
- Testing/QA: @qa-testing-maria
- Product: @product-owner-daniela
- Security: @security-auditor-carlos

**Emergencias:**
- Production Down: @devops-infrastructure-jorge
- Security Issue: @security-auditor-carlos
- OpenAI Budget Exceeded: @backend-ai-workers-bolivar

### Repositorios

- **Main:** `github.com/gpbikes/gp-bikes-ai` (a crear)
- **Upstream:** `github.com/chatwoot/chatwoot`
- **AI SDK:** `github.com/chatwoot/ai-agents`

### Dashboards

- **CI:** GitHub Actions
- **Monitoring:** Grafana (a configurar)
- **Errors:** Sentry (a configurar)
- **Costs:** OpenAI Dashboard

### Communication

- **Daily:** Slack #gp-bikes-ai (9:00am COT)
- **Weekly:** Zoom Sprint Reviews (viernes 3pm)
- **Async:** GitHub Discussions

---

## ✅ Próximos Pasos Inmediatos

### Esta Semana (Preparación Sprint 1)

**Daniela (Product Owner):**
- [ ] Presentar roadmap a stakeholders GP Bikes
- [ ] Obtener aprobación de budget ($2,600 USD/mes)
- [ ] Negociar WhatsApp Business API tier empresarial
- [ ] Refinar backlog Sprint 1 con equipo

**Jorge (DevOps):**
- [ ] Provisionar cuentas Railway/AWS
- [ ] Setup repositorio GitHub gpbikes/gp-bikes-ai
- [ ] Crear proyectos Sentry + Grafana

**Simón (Architect):**
- [ ] Fork chatwoot/chatwoot v4.6.0
- [ ] Diseñar schema custom_attributes
- [ ] Documentar event listeners disponibles

**Bolívar (Backend):**
- [ ] Obtener OpenAI API key (organización GP Bikes)
- [ ] Investigar SDK ai-agents (PoC básico)
- [ ] Listar 25 modelos Yamaha 2025 para catalog

**María (QA):**
- [ ] Setup RSpec + VCR + FactoryBot
- [ ] Crear templates de tests
- [ ] Definir estrategia E2E con Capybara

**Carlos (Security):**
- [ ] Review inicial de Chatwoot (vulnerabilities conocidas)
- [ ] Definir checklist de security para cada sprint

### Sprint 1 Kickoff

**Lunes 1 de Octubre - 9am:**
- Sprint Planning (2h)
- Asignación de tareas
- Setup de ambiente local (pair programming)

**Daily Standups:**
- 9:00am COT todos los días
- Slack channel: #gp-bikes-ai-daily

**Sprint 1 Review:**
- Viernes 12 de Octubre - 3pm
- Demo de GreetingWorker funcional
- Retrospective

---

## 📚 Documentación Adicional

- **User Stories Completas:** [`docs/user_stories/`](./docs/user_stories/)
- **Flujos Conversacionales:** [`docs/flows/`](./docs/flows/)
- **Framework de Métricas:** [`docs/kpis/metrics-framework.md`](./docs/kpis/metrics-framework.md)
- **Sprint 1 Detallado:** [`docs/sprints/sprint-01-plan.md`](./docs/sprints/sprint-01-plan.md)
- **Guía de Arquitectura:** [`CLAUDE.md`](./CLAUDE.md)

---

**Documento preparado por:** Daniela (Product Owner)
**Aprobado por:** [Pendiente]
**Última actualización:** 30 de septiembre de 2025
**Próxima revisión:** Post Sprint 1 (12 de octubre de 2025)

---

*Este roadmap es un documento vivo. Será actualizado al final de cada sprint con learnings, ajustes de scope y nuevas prioridades basadas en feedback del equipo y métricas reales.*
