# Bugs abiertos y fixes aplicados — fork PaluHub (Chatwoot)

> Documento vivo. Cada bug tiene ID, severidad, archivo, descripción, fix aplicado
> y cómo probarlo. Trazabilidad cruzando con `INTERNAL_TASKS_AND_ALERTS.md`.

**Última actualización:** fix `B-NEW-13` report panel pivot collapsing agent
rows (2026-07-23, branch `fix/report-panels-pivot-agent-rows`). Antes:
`B-NEW-12` WhatsApp Flow nfm_reply. Auditoría previa pre–chats grupales
(2026-07-11), branch `feat/internal-tasks` (PR #3).

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
| B-NEW-11 | Media | No | ✅ Re-fijado (2026-07-21) — regresión en `d54c4092d` revirtió attended; restaurado en `feat/automation-formulas-and-date-vars` |
| B-NEW-12 | Media | No | ✅ Fijado — Flow nfm_reply: i18n restaurado + sin confirmación outbound al cliente |
| B-NEW-13 | 🔴 Alta (prod) | No | ✅ Fijado — pivot summary rows seeded from flat summary; no more agent collapse |

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

### B-NEW-11 — Automation replies no marcaban la conversación como attended

**Severidad:** Media — afecta reporting (`Unattended`/`Unassigned` counts en `LiveReports`) y SLA. Bug latente en cualquier cuenta que use automatizaciones (`AutomationRules::ActionService#send_message`) o macros con `send_message`.

**Síntoma:** una automatización que responde automáticamente a un cliente no limpiaba `conversation.waiting_since` ni seteaba `conversation.first_reply_created_at`. La conversación quedaba en el bucket "Unattended" aunque la respuesta ya se había enviado y entregado.

**Causa raíz:**

`Message#human_response?` (`app/models/message.rb:371`) tenía esta firma:

```ruby
def human_response?
  outgoing? &&
    content_attributes['automation_rule_id'].blank? &&   # bloqueaba automation
    additional_attributes['campaign_id'].blank? &&
    (sender.is_a?(User) || content_attributes['external_echo'].present?)
end
```

Cuando una automation corría vía `AutomationRules::ActionService#send_message` (`app/services/automation_rules/action_service.rb:46`), creaba el `Message` con:
- `content_attributes: { automation_rule_id: @rule.id }` ← bloqueaba el chequeo
- `sender = nil` (porque `MessageBuilder.new(nil, ...)`)

Resultado: `human_response?` → `false` → `valid_first_reply?` → `false` → no se disparaba `FIRST_REPLY_CREATED`, no se limpiaba `waiting_since`, no se asignaba agente default.

Bug secundario encontrado durante el fix: `valid_first_reply?` (línea 224) tenía un **off-by-one**. El filtro era:

```ruby
return false if conversation.messages.outgoing
                            .where.not(sender_type: [...])
                            .where.not(private: true)
                            .where("(additional_attributes->'campaign_id') is null")
                            .count > 1
```

Como `valid_first_reply?` corre **dentro del after_save** (`dispatch_create_events`, línea 387), el mensaje actual ya está persistido cuando se cuenta. Con `count > 1`, **cualquier segundo outgoing no-bot ya impedía que se setee `first_reply_created_at`** — incluso respuestas legítimas de agentes humanos en una conversación con respuestas previas.

**Fix aplicado:**

1. **`Message#human_response?`** — simplificado a la regla de negocio real: cualquier respuesta saliente del sistema cuenta como respuesta, excepto notas privadas y campañas outbound (que son outreach masivo, no replies).

   ```ruby
   def human_response?
     outgoing? && !private? && additional_attributes['campaign_id'].blank?
   end
   ```

   Cobertura post-fix:
   - ✅ Mensajes de agente humano → cuentan (igual que antes)
   - ✅ Mensajes de AgentBot / Captain → cuentan (ya estaban)
   - ✅ Eco del canal (WhatsApp echo, Instagram echo) → cuentan (igual que antes)
   - ✅ Automation salientes → cuentan (**antes NO**)
   - ❌ Notas privadas → no cuentan
   - ❌ Campañas outbound → no cuentan

2. **`Message#valid_first_reply?`** — fix off-by-one: excluye el message actual (`where.not(id: id)`) y threshold `count.positive?` en vez de `count > 1`.

**Archivos tocados:**

- `app/models/message.rb` (líneas 224-233 y 371-380)
- `spec/models/message_spec.rb` (líneas 228-236) — el test "does not update first reply if sent by automation" se invirtió a "updates first reply if sent by automation" reflejando la nueva semántica

**Migración BD:** no requerida (cambia solo lógica del modelo).

**Verificación end-to-end** (smoke test contra BD del contenedor):

```
After automation reply:
  first_reply_created_at: SET ✓
  waiting_since: nil ✓
  matches unattended scope? false ✓
  human_response? true ✓

Negative cases:
  campaign message → human_response? false ✓
  private message  → human_response? false ✓
  incoming message → human_response? false ✓

Eventos disparados:
  first.reply.created ✓
  reply.created ✓
  conversation.updated (con first_reply_created_at + waiting_since cleared) ✓
```

**Cómo probar en navegador:**

1. Hard refresh (Ctrl+Shift+R).
2. Settings → Automations → crear/editar una rule de `message_created` → acción `Send a Message`.
3. Disparar un mensaje entrante en una conversación donde la automation aplique.
4. Verificar en el chatlist:
   - La conversación **sale del filtro "Unattended"** (`Unattended count` baja).
   - Aparece en "Attended".
   - `conversation.first_reply_created_at` queda seteado al timestamp del reply de automation.

**Aprendizaje / nota arquitectónica:**

El filtro `human_response?` se usaba como "single source of truth" para first-reply semantics. Tener un campo técnico (`content_attributes['automation_rule_id']`) bloqueando el reconocimiento de un reply fue un acoplamiento accidental. La regla correcta es semántica: **es un reply del sistema si sale hacia el contacto y no es nota privada ni campaña**. El flag `automation_rule_id` se mantiene en `content_attributes` para trazabilidad, pero no debe afectar el lifecycle de la conversación.

`automation_rule_id` queda en `content_attributes` por compatibilidad con los specs existentes en `spec/listeners/automation_rule_listener_old_spec.rb` (líneas 629, 731-732). Si en el futuro se quisiera unificar con `additional_attributes` (donde está `campaign_id`), es un cambio de trazabilidad, no de comportamiento.

**Estado:** ✅ Fijado originalmente (2026-07-20). **Regresión:** el commit
`d54c4092d` (`fix(conversations): resolve toggle_status I18n and keep agent-only first-reply semantics`)
revirtió `human_response?` a solo `User` + excluyó `automation_rule_id` de nuevo
en `valid_first_reply?` (el hotfix de toggle_status/I18n de ese commit es legítimo
y no se toca). **Re-fijado** 2026-07-21 en `feat/automation-formulas-and-date-vars`:
restaurar `human_response?` amplio (agent + automation + bot/echo; excluye private
y campaigns) y quitar el filtro `automation_rule_id` de `valid_first_reply?`,
conservando el off-by-one (`where.not(id: id)` + `count.positive?`).

Decisión de producto (aprobada): automation e IA/AgentBot/Captain cuentan como
attended igual que un agente; colores de burbuja siguen familia bot (iris);
private notes y campaigns no cuentan.

### B-NEW-12 — WhatsApp Flow nfm_reply: i18n perdido + confirmación enviada al cliente

**Severidad:** Media — el agente ve `Translation missing` y el cliente recibe un resumen
técnico (a veces con keys rotas) que debía ser solo interno.

**Síntoma:**

1. Tras completar un Flow, el bubble incoming muestra
   `Translation missing: en.conversations.messages.whatsapp.flow_response.received`.
2. Se crea un outgoing que WhatsApp entrega al contacto con header/footer también
   como `Translation missing` + los campos del form.

**Causa raíz:**

- Keys `conversations.messages.whatsapp.flow_response.*` se agregaron en `23ce702b1`
  y se borraron por accidente en `34d714fbb` (export de contactos).
- `Whatsapp::FlowConfirmationService` creaba `message_type: :outgoing` sin
  `private: true` → `SendReplyJob` lo enviaba al canal.

**Fix aplicado:**

1. Restaurar `flow_response.received` / `flow_response.empty` en `config/locales/en.yml`.
2. Eliminar auto-confirmación al cliente (`send_flow_confirmation`,
   `FlowConfirmationService`, `format_confirmation`). El incoming ya guarda texto
   legible + `content_attributes['whatsapp_flow_response']`.

**Archivos:**

- `config/locales/en.yml`
- `app/services/whatsapp/incoming_message_base_service.rb`
- `app/services/whatsapp/flow_response_formatter.rb`
- `app/services/whatsapp/flow_confirmation_service.rb` (eliminado)
- specs correspondientes

**Migración BD:** no requerida.

**Cómo probar:**

1. Enviar template/Flow → cliente completa.
2. Inbox: un bubble incoming con “Formulario completado:” + campos (sin Translation missing).
3. El cliente no recibe mensaje de confirmación.
4. Tras el Flow, reply libre (`can_reply` / ventana 24h) sigue abierto vía el incoming.

**Estado:** ✅ Fijado 2026-07-23 en `fix/whatsapp-flow-internal-response`.

### B-NEW-13 — Pivot en paneles de reporte colapsa filas de agentes

**Severidad:** Alta (producción) — tras PR #29, tabla resumen de agentes con
`pivot.column_attribute` (p.ej. atributo tipo “venta”/producto) mostraba **una
sola fila** o perdía agentes; se esperaba cruce Excel (agentes × valores).

**Síntoma:**

1. Panel agent summary sin pivot: N agentes.
2. Al poner un CA en Columnas (pivot): quedan 1–pocos agentes; el resto
   desaparece en lugar de mostrar ceros por segmento.

**Causa raíz:**

1. `build_pivot_rows` solo emitía `buckets.keys` — dimensiones vistas al
   escanear conversaciones que además pasan el filtro de `column_values`.
2. El scan usaba `reorder(:id).limit(2000)`, sesgado a conversaciones viejas
   y truncando cuentas grandes → pocos assignees en el bucket.

Flat summary usa `AgentSummaryBuilder` (todos los `account_users`); pivot no.

**Fix aplicado:**

1. Sembrar buckets con los mismos dimension ids que el summary plano
   (`pivot_baseline_dimension_ids`).
2. Acumular con `in_batches` sin el `limit` sesgado (timeout de statement
   sigue acotando).
3. Smoke: `tmp/smoke_pivot_agent_rows.rb` — pivot/subset row count ≥ flat.

**Archivos:**

- `app/services/reports/panel_runner_service.rb`
- `tmp/smoke_pivot_agent_rows.rb`

**Migración BD:** no. Paneles guardados: sin cambio de config (transparente).

**Cómo probar:**

1. Seed demo: `tmp/seed_report_panels_demo.rb`.
2. Smoke: `rails runner tmp/smoke_pivot_agent_rows.rb` → `OK`.
3. UI: panel «Demo Agentes × Ventas» — mismas filas de agente con y sin
   Columnas=Producto; celdas 0 donde no hay cruce.

**Estado:** ✅ Fijado 2026-07-23 en `fix/report-panels-pivot-agent-rows`.

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
