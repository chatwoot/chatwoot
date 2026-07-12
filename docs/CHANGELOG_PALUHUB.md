# Changelog InboxHub (PaluHub)

Formato: [Keep a Changelog](https://keepachangelog.com/).  
Versión del fork: ver [`PALUHUB_VERSION`](../PALUHUB_VERSION) y [`VERSIONING.md`](VERSIONING.md).  
Base Chatwoot documentada por release.

---

## [1.0.0] — 2026-07-12

**Based on Chatwoot** `4.15.1`  
**Tag:** `inboxhub-v1.0.0`  
**Branch:** `develop` (vía `feat/internal-tasks`)

### Added

- Internal Tasks: inbox (Mine / Unclaimed / All), kanban, detalle, notas, claim/start/complete, plantillas, ActionCable.
- Migraciones: `task_templates`, `internal_tasks`, `internal_task_events`, `source_message_id`.
- Team assignment: al asignar un equipo, round-robin a un agente online del team ∩ inbox (`Conversations::TeamAssignmentService`).
- Header conversación: control split “Assign to me” | lista de agentes.
- Contacto: agente asignado al contacto, document number, UX panel.

### Changed

- Lista expandida: más espacio a canal/nombre; filas más compactas.
- Reply box / ContactInfo: menos altura y padding por defecto.
- Tasks: layout siempre condensado (no sigue expand de conversaciones); ancho fijo; avatar de agente; kanban más estrecho sin badge de estado redundante.
- Sidebar Tasks permanece activo en `/tasks/:id`.
- Bulk actions ES: texto más corto + barra sin wrap.

### Fixed

- WhatsApp interactive `action` como objeto (Cloud API).
- Reply preview en notas privadas; botones de plantillas WA en burbujas.
- Tasks: claim races, ACL/policy scope, privacidad de notas privadas / timeline.
- Flicker de lista al añadir nota a una tarea.

### Deploy

Ver [`RELEASE_INBOXHUB_1.0.0.md`](RELEASE_INBOXHUB_1.0.0.md).
