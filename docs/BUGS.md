# Bugs abiertos y fixes aplicados — fork PaluHub (Chatwoot)

> Documento vivo. Cada bug tiene ID, severidad, archivo, descripción, fix aplicado
> y cómo probarlo. Trazabilidad cruzando con `INTERNAL_TASKS_AND_ALERTS.md`.

**Última actualización:** auditoría pre–chats grupales (2026-07-11), branch
`feat/internal-tasks` (PR #3).

---

## 0. Gate: listo para chats grupales internos?

**Veredicto: GO (condicional)**

| Criterio | Estado |
|----------|--------|
| Ningún P0 abierto | ✅ CABLE-TASK-01 + TASK-DESTROY-01 fijados |
| P1 privacidad/ACL/claim | ✅ TASK-CLAIM-01, TASK-SCOPE-01, NOTE-PRIV-01 fijados |
| Smoke 2 browsers realtime | ⚠️ Verificar manualmente tras rebuild (claim 409 FE + cable scoped) |
| P2 no bloqueantes | Abiertos a propósito (validaciones assignee, status libre) |

**Shared infra notes (para diseñar grupales):**

1. ActionCable de tasks ya no hace fan-out a todos los agents — reutilizar el patrón `internal_task_agents` / policy scope.
2. Notas privadas: reglas unificadas en `Conversations::PrivateNoteVisibility` (timeline + MessageFinder + broadcast). Sustituir por `NotePolicy` cuando exista.
3. Presence / `staleThreshold` en `node_modules` sigue sin patch (ops/proxy).
4. Migración 20260711* pendiente de aplicar en cada entorno (`db:migrate`).

---

## 1. Resumen de fixes

| ID | Severidad | Bloquea grupales? | Estado |
|----|-----------|-------------------|--------|
| TASK-001 | Alta | No (timeline) | ✅ Fijado (refactor → PrivateNoteVisibility) |
| TASK-002 | Alta | No | ✅ Fijado |
| TASK-003 | Media | Parcial | ✅ Mejorado con `with_lock` + FE 409 |
| TASK-004 | Media | No | ✅ Fijado |
| TASK-005 | Baja | No | ❌ **Era falso positivo — revertido**: `currentChat` **sí se usa** en TaskDetail.vue:61 y en TaskDetailConversation.vue. Mi reporte original del 2026-07-11 estaba MAL. Removida la entry. |
| UX-001 / UX-002 | Media | No | ✅ Fijado |
| CABLE-TASK-01 | P0 | **Sí** | ✅ Confirmado + fijado |
| TASK-DESTROY-01 | P0 | **Sí** | ✅ Confirmado + fijado |
| TASK-CLAIM-01 | P1 | Sí | ✅ Confirmado + fijado |
| TASK-SCOPE-01 | P1 | Sí | ✅ Confirmado + fijado |
| NOTE-PRIV-01 | P1 | Sí | ✅ Confirmado + fijado |
| B-NEW-01 | Media | No | ✅ Fijado — `InternalTaskEvent#broadcast_task_activity` sin doble dispatch |
| B-NEW-02 | Media | No | ✅ Fijado — guard de bot/Conversation en `resolve_agent` |
| B-NEW-03 | Media | No | ✅ Fijado — `MessageFinder#apply_private_note_visibility` null-safe |
| B-NEW-04 | Baja | No | ✅ Fijado — orden de filas en `ContactInfo.vue` consolidado |
| B-NEW-05 | Baja | No | ✅ Revisado — `v-if` ya cubre el caso; sin cambio necesario |
| B-NEW-09 | 🔴 Media → reclasif. ✅ | No (drift) | ✅ Investigado — migración ya existía; `schema.rb` queda con la columna |
| B-NEW-10 | Baja | No | ✅ Fijado — type-check en `AssignDefaultAgentService#perform` |
| TASK-006 | Baja | No | panel-ai (fuera de alcance Chatwoot) |
| TASK-007 | Baja | No | ContactInfo mojibake — abierto |
| TASK-008 | Baja | No | **Stale** — índice `[:account_id, :active, :position]` ya existe |

---

## 2. Auditoría 2026-07-11 — P0/P1 fijados

### CABLE-TASK-01 — Broadcast de tasks a todos los agents

**Confirmado.** `internal_task_created/updated` usaba `account.agents`.

**Fix:** `internal_task_agents` alinea con `InternalTaskPolicy::Scope` (pool abierto → todos; si no → assignee + miembros del team). Admins siguen vía `user_tokens`.

**Archivo:** `app/listeners/action_cable_listener.rb`

### TASK-DESTROY-01 — Soft-cancel siempre 403

**Confirmado.** `destroy?` no existía → `ApplicationPolicy#destroy?` → `false`.

**Fix:** `destroy?` = `update?` en `InternalTaskPolicy`.

### TASK-CLAIM-01 — Race + FE sin 409

**Confirmado.** Check-then-update sin lock; store no manejaba conflict.

**Fix:** `with_lock` + `reload` en `ClaimService`; store refresca en 409; `useInternalTaskActions` muestra alert.

### TASK-SCOPE-01 — Tasks de conversación / timeline sin ACL

**Confirmado.** Nested index usaba `@conversation.internal_tasks` sin `policy_scope`; timeline listaba todos los task events.

**Fix:** `policy_scope` en nested controller; timeline filtra `visible_task_ids` por Scope.

### NOTE-PRIV-01 — Hilo vs timeline divergentes

**Confirmado.** Timeline filtraba; `MessageFinder` y ActionCable de notas privadas no.

**Fix:** `Conversations::PrivateNoteVisibility` compartido; MessageFinder (dashboard) + `message_broadcast_members` en cable.

### Extra (P2 mínimo)

- Comentarios de task: eliminado doble `dispatch_updated_event` (solo `touch`).
- Index de tasks: `includes(:events)` para N+1 del jbuilder.

---

## 2.1. Segunda pasada de revisión (2026-07-11 tarde)

Después de aplicar los fixes P0/P1, se hizo otra pasada detectando bugs adicionales.

### B-NEW-01 — `InternalTaskEvent#broadcast_task_activity` causaba doble dispatch

**Severidad:** Media — causaba dos broadcasts por cada evento (excepto `created`).
`touch` ya dispara `after_update_commit → dispatch_updated_event`; la llamada extra
a `internal_task.dispatch_updated_event` producía el doble.

**Fix:** eliminado el `dispatch_updated_event` redundante dentro de
`broadcast_task_activity`.

**Archivo:** `app/models/internal_task_event.rb`

```ruby
def broadcast_task_activity
  # touch bumps updated_at and fires after_update_commit → dispatch_updated_event once
  internal_task.touch
end
```

### B-NEW-02 — `AssignDefaultAgentFromFirstReplyService` podía asignar no-Users

**Severidad:** Media — `resolve_agent` retornaba `message.conversation.assignee`
sin type-check. Si assignee era un Bot o Conversation, `update!(assigned_agent: ...)`
crasheaba con `ActiveModel::TypeMismatch`.

**Fix:** narrowed a User con `id.present?`, además de los guards en `perform`.

**Archivo:** `app/services/contacts/assign_default_agent_from_first_reply_service.rb`

```ruby
def resolve_agent
  sender = message.sender
  return sender if sender.is_a?(User) && sender.id.present?

  assignee = message.conversation&.assignee
  return assignee if assignee.is_a?(User) && assignee.id.present?

  nil
end
```

### B-NEW-03 — `MessageFinder` fallaba sin `Current.user`

**Severidad:** Media — procesos background (Sidekiq, exports, scripts sin
sesión) terminaban con `list.select` filtrando TODO mensaje privado
(incluyendo notes que sí vería un humano en sesión).

**Fix:** si `Current.user` es blank, retornar la lista sin filtrar (visibilidad
permisiva para procesos background). Además, inferir `conversation` desde el
primer mensaje si `@conversation` no está seteado.

**Archivo:** `app/finders/message_finder.rb`

```ruby
def apply_private_note_visibility(message_list)
  list = Array(message_list)
  return list if Current.user.blank?
  return list if ActiveModel::Type::Boolean.new.cast(@params[:filter_internal_messages])

  conversation = @conversation || list.first&.conversation
  return list if conversation.blank?

  list.select do |message|
    !message.private? || Conversations::PrivateNoteVisibility.allowed?(
      user: Current.user, message: message, conversation: conversation
    )
  end
end
```

### B-NEW-04 — Layout de `ContactInfo.vue` partía los datos en dos bloques

**Severidad:** Baja — el refactor había dejado `phone + documentNumber` en un
bloque (junto al avatar) y `email + identifier + company + location` en otro
debajo, partiendo la info de contacto arbitrariamente.

**Fix:** consolidados todos los `ContactInfoRow` en una sola columna,
con orden lógico: email → phone → identifier → document → company → location.

**Archivo:** `app/javascript/dashboard/routes/dashboard/conversation/contact/ContactInfo.vue`

### B-NEW-05 — `Avatar` huérfano cuando `showAvatar=false`

**Severidad:** Baja — revisado, no requirió cambio. El `<Avatar>` ya tenía
`v-if="showAvatar"`; el wrapper `flex flex-row items-start gap-3` no genera
espacio visual fuerte cuando el Avatar está oculto (gap con un hijo sigue
siendo razonable).

**Estado:** ❌ No aplicado. Sin cambio necesario.

### B-NEW-09 — `db/schema.rb` drift vs migración ya aplicada

**Severidad:** Media — preocupado al inicio como Alta, **reclasificado tras verificación**.

**Investigación:** al intentar `rails db:migrate` reaplicar la columna, Rails
reportó `DuplicateMigrationNameError` con la migración `20260630120000_add_assigned_agent_id_to_contacts.rb`
(ya existente en `db/migrate/` y aplicada según `schema_migrations`). La columna
`contacts.assigned_agent_id`, su índice `index_contacts_on_assigned_agent_id` y
la FK a `users(id)` **ya estaban presentes en la BD**.

**Conclusión:** la edición manual de `db/schema.rb` era una corrección de drift
(no agregaba nada nuevo), no una migración faltante. Mi diagnóstico inicial fue
incorrecto — el `db/schema.rb` modificado **debe quedarse** (refleja el estado
real de la BD). No creo nueva migración.

**Verificación en BD local:**
```sql
\d contacts
-- assigned_agent_id | bigint | (presente)
-- index_contacts_on_assigned_agent_id btree (assigned_agent_id)
-- fk_rails_cded5b5676 FOREIGN KEY (assigned_agent_id) REFERENCES users(id)
```

**Acción:** revertí mi migración duplicada (`20260711120000`) y mantuve el
`schema.rb` con la columna.

**Aprendizaje:** antes de declarar "falta migración", correr
`SELECT version FROM schema_migrations`. Si el timestamp figura, **la
migración YA está aplicada** aunque el `schema.rb` estuviera desactualizado.
El "fix" entonces es regenerar `schema.rb` con `rails db:schema:dump`, no
crear migración nueva.

**Estado:** ✅ Documentado y corregido.
Migración `db/migrate/20260711120000_add_assigned_agent_id_to_contacts.rb` borrada.

### B-NEW-10 — `Contact.update!` con type-check insuficiente

**Severidad:** Baja — defensa explícita en `AssignDefaultAgentService#perform`
para no asignar un agente inválido al contacto (Bot, Conversation, etc.).

**Fix:** agregado `return unless agent.is_a?(User)` y `return if agent.id == contact.id`
(previene self-assignment).

**Archivo:** `app/services/contacts/assign_default_agent_from_first_reply_service.rb`

```ruby
def perform
  return unless message.human_response? && !message.private?

  contact = message.conversation&.contact
  return if contact.blank?
  return if contact.assigned_agent_id.present?

  agent = resolve_agent
  return if agent.blank?
  return unless agent.is_a?(User)
  return if agent.id == contact.id

  contact.update!(assigned_agent: agent)
end
```

---

## 3. Fijados en sesión anterior (tasks / UX)

### TASK-001 — Notas privadas en timeline

Reglas movidas a `Conversations::PrivateNoteVisibility` (misma lógica).

### TASK-002 — `clearSelectedState` en módulo internalTasks

### TASK-003 / TASK-004 — claim 409 JSON + depends_on misma cuenta

### UX-001 / UX-002 — reply preview notas + snapshot botones WA

Ver secciones 5b previas / commits en PR #3.

---

## 4. Out of scope (NO tocado)

- Kanban drag-and-drop
- Default `enable_audio_alerts`
- Patch ActionCable `staleThreshold` en `node_modules`
- Instagram OAuth POST
- panel-ai / Meta Live
- Validaciones P2: assignee/team same-account, status transitions estrictas

---

## 5. Bugs abiertos (no bloquean grupales)

| ID | Descripción | Severidad | Notas |
|----|-------------|-----------|-------|
| TASK-006 | Código muerto BotInboxMenuEditor (panel-ai) | Baja | Fuera de este repo |
| TASK-007 | Mojibake emoji en `ContactInfo.vue` | Baja | Cosmético |
| TASK-008 | Índice position | — | **Stale / cerrado** |
| P2-VALID | assignee/team_id sin check same-account; status libre en PATCH | Baja | Backlog |
| CABLE-OPS | presence / proxy idle / staleThreshold | Ops | Documentado en INTERNAL_TASKS |

---

## 5b. UX fijados (reply / plantillas WA)

### UX-001 — Preview reply-to en notas privadas

`ReplyBox.vue` — `shouldShowReplyToMessage` muestra preview en modo nota.

### UX-002 — Botones plantilla WA en bubble

Snapshot `content_attributes.template_buttons` + render en `Text/Index.vue`.

---

## 6. Cómo probar (smoke post-auditoría)

```powershell
# Ruby (montado en ./app) — restart
docker compose -f docker-compose.dokploy.yml -f docker-compose.dokploy.fork.yml restart chatwoot-rails chatwoot-sidekiq

# Vue (claim 409 alert) — rebuild
docker compose -f docker-compose.dokploy.yml -f docker-compose.dokploy.fork.yml up -d --build chatwoot-rails
```

1. Soft-cancel/destroy task vía API como assignee → 200 (antes 403).
2. Task asignada a team A: agent de team B **no** recibe ActionCable create/update.
3. Claim concurrente → uno 200, otro 409 + alert FE.
4. Agente no assignee/no team: hilo **y** timeline ocultan notas privadas ajenas.
5. Nested `/conversations/:id/internal_tasks` solo lista tasks visibles por policy.
6. Navegar `/tasks` sin errores de consola.

---

## 7. Próximos pasos

1. Smoke manual items 1–6 arriba.
2. Commit/push a PR #3 cuando se pida.
3. Diseñar chats grupales reutilizando cable scoped + PrivateNoteVisibility / futura NotePolicy.
4. Specs mínimos: claim lock, destroy policy, PrivateNoteVisibility (recomendado antes de merge a prod).

---

## 8. Docs relacionadas

- [`INTERNAL_TASKS_AND_ALERTS.md`](INTERNAL_TASKS_AND_ALERTS.md)
- [`AGENTS.md`](../AGENTS.md)
