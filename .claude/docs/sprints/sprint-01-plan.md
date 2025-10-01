# Sprint 1 Plan - Foundation

**Duración:** 2 semanas (1-12 de octubre de 2025)
**Objetivo:** Establecer infraestructura base completa y primer AI Worker funcional (GreetingWorker)

---

## 🎯 Sprint Goal

> "Al final de Sprint 1, tendremos un ambiente de desarrollo completamente funcional con Docker Compose, CI/CD pipeline, BaseAiWorker implementado y testeado, y GreetingWorker respondiendo automáticamente a primeros mensajes en WhatsApp."

---

## 👥 Team Capacity

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

---

## 📋 Sprint Backlog

### User Stories

| ID | Story | Points | Owner | Status |
|----|-------|--------|-------|--------|
| US-001 | BaseAiWorker | 18h | Bolívar + María | ⬜ To Do |
| US-002 | GreetingWorker | 13h | Bolívar + María | ⬜ To Do |

### Technical Tasks

#### Semana 1: Infrastructure Setup

**Día 1-2: Docker & Local Environment**

| # | Tarea | Owner | Horas | Status |
|---|-------|-------|-------|--------|
| 1.1 | Fork chatwoot/chatwoot v4.6.0 | Jorge | 2h | ⬜ |
| 1.2 | Docker Compose con PostgreSQL 16 + Redis 7 | Jorge | 4h | ⬜ |
| 1.3 | Configuración inicial Rails 7.2 | Simón | 3h | ⬜ |
| 1.4 | Setup RSpec + FactoryBot + VCR | María | 4h | ⬜ |
| 1.5 | Integración OpenAI API (test básico) | Bolívar | 3h | ⬜ |
| 1.6 | .env.development template | Jorge | 1h | ⬜ |
| 1.7 | Documentación README_GPBIKES.md (setup) | Daniela | 2h | ⬜ |

**Total Día 1-2:** 19 horas

**Día 3-4: CI/CD Pipeline**

| # | Tarea | Owner | Horas | Status |
|---|-------|-------|-------|--------|
| 2.1 | GitHub Actions workflow: .github/workflows/ci.yml | Jorge | 4h | ⬜ |
| 2.2 | Job: lint (Rubocop + ESLint) | Jorge | 2h | ⬜ |
| 2.3 | Job: test (RSpec con coverage) | Jorge | 3h | ⬜ |
| 2.4 | Job: security_scan (bundle-audit + brakeman) | Carlos | 2h | ⬜ |
| 2.5 | Branch protection rules | Jorge | 1h | ⬜ |
| 2.6 | CI badge en README | Jorge | 0.5h | ⬜ |

**Total Día 3-4:** 12.5 horas

#### Semana 2: Core Implementation

**Día 5-7: BaseAiWorker**

| # | Tarea | Owner | Horas | Status |
|---|-------|-------|-------|--------|
| 3.1 | app/services/ai_workers/base_ai_worker.rb | Bolívar | 8h | ⬜ |
| 3.2 | lib/ai_workers/openai_wrapper.rb | Bolívar | 4h | ⬜ |
| 3.3 | lib/ai_workers/memory_manager.rb | Bolívar | 6h | ⬜ |
| 3.4 | spec/services/ai_workers/base_ai_worker_spec.rb | María | 8h | ⬜ |
| 3.5 | VCR cassettes (3 scenarios) | María | 2h | ⬜ |
| 3.6 | YARD documentation | Bolívar | 2h | ⬜ |

**Total Día 5-7:** 30 horas

**Día 8-10: Configuration System**

| # | Tarea | Owner | Horas | Status |
|---|-------|-------|-------|--------|
| 4.1 | config/ai_workers/agents.yml | Simón | 2h | ⬜ |
| 4.2 | config/ai_workers/prompts.yml | Simón | 2h | ⬜ |
| 4.3 | config/ai_workers/motorcycle_catalog.yml (stub) | Daniela | 1h | ⬜ |
| 4.4 | config/initializers/gp_bikes.rb | Simón | 3h | ⬜ |
| 4.5 | app/models/concerns/gp_bikes_contact_attributes.rb | Simón | 3h | ⬜ |
| 4.6 | spec/config/ai_workers_config_spec.rb | María | 2h | ⬜ |

**Total Día 8-10:** 13 horas

**Día 11-12: ConversationRouter**

| # | Tarea | Owner | Horas | Status |
|---|-------|-------|-------|--------|
| 5.1 | app/listeners/gp_bikes_message_listener.rb | Simón | 4h | ⬜ |
| 5.2 | lib/ai_workers/conversation_router.rb | Simón | 6h | ⬜ |
| 5.3 | config/initializers/event_listeners.rb | Simón | 1h | ⬜ |
| 5.4 | spec/listeners/gp_bikes_message_listener_spec.rb | María | 3h | ⬜ |
| 5.5 | spec/lib/ai_workers/conversation_router_spec.rb | María | 3h | ⬜ |

**Total Día 11-12:** 17 horas

**Día 13-14: GreetingWorker**

| # | Tarea | Owner | Horas | Status |
|---|-------|-------|-------|--------|
| 6.1 | app/services/ai_workers/greeting_worker.rb | Bolívar | 5h | ⬜ |
| 6.2 | System prompt en prompts.yml | Bolívar | 1h | ⬜ |
| 6.3 | spec/services/ai_workers/greeting_worker_spec.rb | María | 4h | ⬜ |
| 6.4 | VCR cassettes (3 scenarios: genérico, nombre, largo) | María | 2h | ⬜ |
| 6.5 | spec/integration/greeting_flow_spec.rb | María | 2h | ⬜ |
| 6.6 | Manual testing en desarrollo | Bolívar | 1h | ⬜ |
| 6.7 | YARD documentation | Bolívar | 1h | ⬜ |

**Total Día 13-14:** 16 horas

---

## ✅ Definition of Done

### Infrastructure (Día 1-4)

- [ ] `docker-compose up` levanta ambiente completo en <2 minutos
- [ ] `rails console` accesible
- [ ] `rspec` ejecuta sin errores (incluso sin tests aún)
- [ ] PostgreSQL 16 running con base de datos creada
- [ ] Redis 7 running y accesible
- [ ] OpenAI API key configurado y testeado
- [ ] CI pipeline verde en GitHub Actions
- [ ] Equipo completo puede desarrollar localmente (validado por 3+ personas)
- [ ] README_GPBIKES.md con instrucciones de setup

### BaseAiWorker (Día 5-7)

- [ ] Código implementado en `app/services/ai_workers/base_ai_worker.rb`
- [ ] Métodos abstractos: `should_trigger?`, `process`
- [ ] Método `call_openai` con retry logic (3 intentos, exponential backoff)
- [ ] Método `update_contact_memory` funcional
- [ ] Método `send_message` funcional
- [ ] Tests RSpec: 100% coverage (SimpleCov)
- [ ] VCR cassettes grabados para OpenAI
- [ ] Rubocop sin offenses
- [ ] YARD documentation completa
- [ ] PR aprobado por Simón

### Configuration System (Día 8-10)

- [ ] YAML configs creados y validados
- [ ] Initializer carga configs al boot sin errores
- [ ] Schema de custom_attributes definido
- [ ] Tests verifican carga correcta de configs
- [ ] Documentación de estructura de configs

### ConversationRouter (Día 11-12)

- [ ] Listener registrado en event system
- [ ] Router rutea mensajes correctamente
- [ ] Tests unitarios pasando
- [ ] Logs muestran decisiones de routing

### GreetingWorker (Día 13-14)

- [ ] Worker se activa solo en primer mensaje
- [ ] Responde en <2 segundos (validado con VCR)
- [ ] Captura nombre si se menciona
- [ ] Almacena datos en custom_attributes
- [ ] Tests unitarios: >= 95% coverage
- [ ] Integration test pasando
- [ ] Manual test exitoso en docker-compose local
- [ ] PR aprobado por Simón y Daniela (business logic)

### General (Fin de Sprint)

- [ ] Todos los tests pasando: `rspec` verde
- [ ] CI pipeline verde
- [ ] Coverage >= 90%
- [ ] Rubocop sin offenses críticos
- [ ] Security scan sin vulnerabilidades altas
- [ ] Documentación actualizada
- [ ] Demo funcionando para Sprint Review

---

## 🚧 Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación | Owner |
|--------|--------------|---------|------------|-------|
| OpenAI API key no disponible | Media | Alto | Usar VCR cassettes pre-grabados, key de prueba | Bolívar |
| Team no familiar con Chatwoot | Alta | Medio | Pair programming + docs, sesión de onboarding | Simón |
| Docker issues en Mac M1 | Baja | Medio | Documentar workarounds específicos | Jorge |
| Scope creep (features extras) | Media | Alto | Daniela refuerza scope, rechaza cambios mid-sprint | Daniela |
| VCR cassettes difíciles de grabar | Baja | Bajo | Grabar manualmente con postman primero | María |

---

## 📅 Ceremonies

### Daily Standup
**Horario:** 9:00am COT (lunes a viernes)
**Duración:** 15 minutos max
**Plataforma:** Zoom + Slack #gp-bikes-daily

**Agenda:**
1. ¿Qué hice ayer?
2. ¿Qué haré hoy?
3. ¿Tengo blockers?

**Formato en Slack (si async):**
```
🤖 Daily Update - [Nombre]

✅ Yesterday:
- Task 1
- Task 2

🔨 Today:
- Task 3
- Task 4

🚧 Blockers:
- None / Blocker description
```

### Sprint Planning
**Fecha:** Lunes 1 de Octubre, 9am COT
**Duración:** 2 horas
**Attendees:** Todo el equipo

**Agenda:**
1. Review Sprint Goal (15 min)
2. Review User Stories: US-001, US-002 (30 min)
3. Task breakdown y asignación (45 min)
4. Confirmar Definition of Done (15 min)
5. Q&A y concerns (15 min)

### Sprint Review
**Fecha:** Viernes 12 de Octubre, 3pm COT
**Duración:** 1 hora
**Attendees:** Equipo + Stakeholders GP Bikes

**Agenda:**
1. Demo GreetingWorker funcionando en vivo (20 min)
2. Review métricas: velocity, coverage, bugs found (15 min)
3. Feedback de stakeholders (15 min)
4. What's next (Sprint 2 preview) (10 min)

### Sprint Retrospective
**Fecha:** Viernes 12 de Octubre, 4:30pm COT
**Duración:** 1 hora
**Attendees:** Solo equipo (sin stakeholders)

**Agenda:**
1. ¿Qué salió bien? (15 min)
2. ¿Qué salió mal? (15 min)
3. ¿Qué mejorar en Sprint 2? (20 min)
4. Action items con owners (10 min)

---

## 📊 Sprint Metrics

### Tracking

**Velocity:**
- Planned: 65 horas (US-001 + US-002 + infra tasks)
- Actual: TBD (actualizar en retrospective)

**Quality:**
- Target Coverage: >= 90%
- Actual Coverage: TBD
- Bugs Found: TBD
- Bugs Fixed: TBD

**Blockers:**
- Total Blockers: 0
- Avg Resolution Time: N/A

---

## 🎯 Success Criteria

Al final de Sprint 1, debemos poder:

1. **Levantar ambiente completo** con un solo comando: `docker-compose up`
2. **Ver CI pipeline verde** en GitHub Actions
3. **Enviar mensaje WhatsApp** y recibir respuesta automática del GreetingWorker
4. **Ver custom_attributes actualizados** en Contact después de interacción
5. **Ejecutar todos los tests** con `rspec` y ver 100% pass rate
6. **Demostrar a stakeholders** que el sistema básico funciona

---

## 📝 Notes

- Este sprint es **foundation crítica** para todos los sprints futuros
- Priorizar **calidad sobre velocidad** - mejor tomarnos tiempo para hacerlo bien
- Si algo toma más tiempo del estimado, **comunicar inmediatamente** en daily
- **No hay features nuevas** mid-sprint - scope está locked
- Daniela es **single source of truth** para acceptance criteria

---

**Sprint Planning Date:** 1 de Octubre de 2025
**Sprint Start:** 1 de Octubre de 2025
**Sprint End:** 12 de Octubre de 2025
**Sprint Review:** 12 de Octubre, 3pm COT
**Sprint Retrospective:** 12 de Octubre, 4:30pm COT

---

*¡Vamos equipo! Este es el inicio de algo grande. 🚀*
