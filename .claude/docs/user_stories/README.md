# User Stories - GP Bikes AI Assistant

Este directorio contiene las user stories priorizadas para el desarrollo del sistema.

---

## 📋 Índice de User Stories

### Phase 1: Fundación (Semanas 1-2)

| ID | Título | Prioridad | Sprint | Estado | Archivo |
|----|--------|-----------|--------|--------|---------|
| US-001 | BaseAiWorker | P0 | 1 | ✅ Documented | [US-001](./US-001-base-ai-worker.md) |
| US-002 | GreetingWorker | P0 | 1 | ✅ Documented | [US-002](./US-002-greeting-worker.md) |

### Phase 2: Core AI Workers (Semanas 3-6)

| ID | Título | Prioridad | Sprint | Estado | Archivo |
|----|--------|-----------|--------|--------|---------|
| US-003 | Lead Qualification | P0 | 3 | ✅ Documented | [US-003](./US-003-lead-qualification.md) |
| US-004 | Product Catalog | P0 | 4 | ⬜ Pending | [US-004](./US-004-product-catalog.md) |
| US-005 | Service Scheduling | P1 | 5 | ⬜ Pending | [US-005](./US-005-service-scheduling.md) |
| US-006 | Financing Calculator | P1 | 6 | ⬜ Pending | [US-006](./US-006-financing-calculator.md) |

### Phase 3: Advanced Workers (Semanas 7-9)

| ID | Título | Prioridad | Sprint | Estado | Archivo |
|----|--------|-----------|--------|--------|---------|
| US-007 | Automated Follow-Up | P1 | 7-8 | ⬜ Pending | [US-007](./US-007-automated-followup.md) |
| US-008 | Post-Sale Support | P2 | 9 | ⬜ Pending | [US-008](./US-008-postsale-support.md) |

---

## 🎯 Prioridades

### P0 - Bloqueantes
**Definición:** Críticas para el MVP. Sin estas, el sistema no funciona.
- US-001: BaseAiWorker (base de todos los workers)
- US-002: GreetingWorker (primera impresión del cliente)
- US-003: Lead Qualification (core ROI del sistema)
- US-004: Product Catalog (recomendaciones = ventas)

### P1 - Altas
**Definición:** Importantes para valor de negocio completo. Deben estar en versión 1.0.
- US-005: Service Scheduling (diferenciador competitivo)
- US-006: Financing Calculator (habilita compras sin presupuesto completo)
- US-007: Automated Follow-Up (maximiza conversión de leads tibios)

### P2 - Medias
**Definición:** Valor agregado. Pueden ser post-launch quick wins.
- US-008: Post-Sale Support (retención, NPS, mantenimientos)

---

## 📝 Formato de User Stories

Todas las user stories siguen este formato:

```markdown
# US-XXX: Título

**Sprint:** X (Semana Y)
**Prioridad:** P0/P1/P2 - Descripción
**Estimación:** X horas
**Owner:** Nombre(s)

## User Story
Como [rol],
Quiero [funcionalidad],
Para [beneficio].

## Acceptance Criteria
- [ ] Criterio 1
- [ ] Criterio 2
...

## Technical Implementation
[Detalles técnicos]

## Tests
[Casos de test]

## Definition of Done
[Checklist]

## Dependencies
[Prerequisitos]

## Notes
[Contexto adicional]
```

---

## 🔄 Workflow de User Stories

### 1. Backlog Refinement (Semanal - Lunes)
- Daniela presenta nuevas user stories
- Equipo estima (planning poker)
- Se asignan a sprints

### 2. Sprint Planning (Inicio de Sprint)
- Seleccionar user stories del sprint
- Asignar owners
- Confirmar acceptance criteria

### 3. Development
- Owner implementa según acceptance criteria
- Tests escritos ANTES de código (TDD)
- PR cuando todos los criteria están ✅

### 4. Review & Acceptance
- Code review por architect (Simón)
- Testing por QA (María)
- Business acceptance por PO (Daniela)
- Merge cuando todo está ✅

---

## ✅ Definition of Ready (DoR)

Una user story está "Ready" cuando:
- [ ] Tiene acceptance criteria claros y medibles
- [ ] Tiene estimación de horas
- [ ] Owner asignado
- [ ] Dependencies identificadas
- [ ] Technical approach discutido
- [ ] Test strategy definida

## ✅ Definition of Done (DoD)

Una user story está "Done" cuando:
- [ ] Código implementado según acceptance criteria
- [ ] Tests escritos y pasando (coverage >= 90%)
- [ ] Code review aprobado
- [ ] Documentación actualizada (YARD, README)
- [ ] Linter sin errores (Rubocop)
- [ ] Merged a branch principal
- [ ] Demostrado en sprint review
- [ ] Product Owner acepta como completa

---

## 📊 Tracking de Progreso

### Sprint 1 (Semanas 1-2): Foundation
- [x] US-001: BaseAiWorker
- [x] US-002: GreetingWorker

**Velocity:** 65 horas (2 user stories)

### Sprint 3 (Semana 3): Lead Qualification
- [ ] US-003: Lead Qualification

**Velocity Estimada:** 42 horas (1 user story)

---

## 🎓 Referencias

- [README_ROADMAP.md](../../README_ROADMAP.md) - Roadmap completo 12 semanas
- [CLAUDE.md](../../CLAUDE.md) - Arquitectura y guías de desarrollo
- [docs/flows/](../flows/) - Diagramas de flujo conversacional
- [docs/kpis/](../kpis/) - Framework de métricas

---

**Última actualización:** 30 de septiembre de 2025
**Próxima revisión:** Post Sprint 1 (12 de octubre de 2025)
