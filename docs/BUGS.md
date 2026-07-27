# Bugs abiertos y fixes aplicados — fork PaluHub (Chatwoot)

> Documento vivo. Cada bug tiene ID, severidad, archivo, descripción, fix aplicado
> y cómo probarlo. Trazabilidad cruzando con `INTERNAL_TASKS_AND_ALERTS.md`.

**Última actualización:** hotfix `B-NEW-39` skip outbound si ventana Meta/WA
cerrada (2026-07-27). Antes: feature `B-NEW-38` automation audit private note
(2026-07-27). Antes: hotfix `B-NEW-37` select fecha/datetime en
time automation schedule (2026-07-27). Antes: hotfix `B-NEW-36` exigir agente humano + selector
contacto transparente (2026-07-27). Antes: hotfix `B-NEW-35` BR guard skip
en automations (2026-07-27). Antes: hotfix `B-NEW-34` motivo al posponer (nota FE +
snooze errors) (2026-07-27). Antes: hotfix `B-NEW-33` dialog BR submit
accidental (MultiSelect type=button) (2026-07-27). Antes: feature `B-NEW-32`
business rules ConditionRow + categorías + multi-status (2026-07-27). Antes:
feature `B-NEW-31` business rules contact attrs + zero-as-blank + TYPE_HELP
(2026-07-27). Antes: hotfix `B-NEW-30` toggle_status 500
(`activity_message_params` kwargs) + resolve modal currency/percent (2026-07-27).
Antes: hotfix `B-NEW-29` dashboard JS post-4.16.1
(`hasFilteredUnreadCounts` / `useI18n`) (2026-07-26). Antes: hotfix
`B-NEW-28` api_and_webhooks (login 500 post 4.16.1) (2026-07-26). Antes:
polish `B-NEW-26` flows layout/acciones/i18n
(2026-07-24). Antes: fix `B-NEW-25` flows actions cards/dropdown clip
(2026-07-24). Antes: polish `B-NEW-24` flows lista/categoría/drawer/inspector
(2026-07-24). Antes: polish `B-NEW-23` flows editor layout/perf/buttons
(2026-07-24). Antes: fix `B-NEW-22` flows canvas + handoff note legible
(2026-07-24). Antes: `B-NEW-20` report panel full-scan (aggregation +
flat CA measures) (2026-07-24, branch `fix/report-panels-correctness`). Antes:
`B-NEW-19` pivot name/rank = 0 + fila Sin asignar
(2026-07-24, branch `fix/report-panels-pivot-identity`). Antes:
`B-NEW-13` report panel pivot collapsing agent
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
| B-NEW-19 | 🔴 Alta (prod) | No | ✅ Fijado — pivot name/rank no longer clobbered to 0; Sin asignar row |
| B-NEW-20 | 🔴 Alta (prod) | No | ✅ Fijado — aggregation + flat CA measures full-scan (no 100/2000 cap) |
| B-NEW-21 | Media | No | ✅ Fijado — panel `date_attribute` + NumericParser + filter UX |
| B-NEW-14 | Feature | No | ✅ Business rules + time automations + multi_list (branch `feat/business-rules-time-multilist`) |
| B-NEW-15 | Flows UI | Baja | ✅ Portado a `feat/business-rules-time-multilist` (model/API/UI/`flows_v1`) |
| B-NEW-16 | 🔴 P0 | No | ✅ Time-rule ledger: conditions before claim + hours window_id from message id/created_at |
| B-NEW-17 | Feature | No | ✅ P0 CRM unlock: time-rule CA actions + relative dates + seguimiento_30d + safe date SQL |
| B-NEW-18 | Smoke | No | ✅ Local Docker smoke: VPS DFIT attrs + seguimiento_30d on `fecha_seguimiento` (conv #154) |
| B-NEW-22 | Flows UX | Baja | ✅ Canvas Vue Flow + nota handoff legible (sin IDs técnicos) |
| B-NEW-23 | Flows UX | Baja | ✅ Polish: full-bleed, footer exit, botones opcionales, títulos, perf |
| B-NEW-24 | Flows UX | Baja | ✅ Activo en lista, categoría, exit drawer, inspector compacto |
| B-NEW-25 | Flows UX | Baja | ✅ Acciones numeradas en cards; dropdown sin clip por overflow |
| B-NEW-26 | Flows UX | Baja | ✅ Acciones horiz., tipos únicos, menubar, panel izq, i18n es |
| B-NEW-28 | 🔴 P0 prod | Sí | ✅ Login 500: faltaba `api_and_webhooks` en features.yml ext_1 |
| B-NEW-29 | 🔴 P0 prod | Sí | ✅ Dashboard JS: `hasFilteredUnreadCounts` + `useI18n` imports |
| B-NEW-30 | 🔴 P0 prod | Sí | ✅ toggle_status 500: `activity_message_params` + modal currency/percent |
| B-NEW-31 | Feature | No | ✅ Business rules: contact attrs + zero-as-blank + TYPE_HELP |
| B-NEW-32 | Feature | No | ✅ Business rules UX: ConditionRow + categorías + multi-status (sin tab tiempo) |
| B-NEW-33 | Bug UX | No | ✅ Dialog BR: MultiSelect/ConditionRow buttons type=button (no submit accidental) |
| B-NEW-34 | Bug UX | No | ✅ Motivo al posponer: FE no bloquea nota a ciegas; snooze con errores BR |
| B-NEW-35 | Bug | No | ✅ BR Guard no bloquea cambios de status hechos por AutomationRule |
| B-NEW-36 | Bug | No | ✅ Exigir assignee = humano/equipo (bot no cuenta); ContactAssignee dropdown |
| B-NEW-37 | UX | No | ✅ Time automation: select CA fecha/datetime (no input libre) |
| B-NEW-38 | Feature | No | ✅ Automation siempre deja nota privada corta de auditoría |
| B-NEW-39 | Bug | No | ✅ Automation no envía outbound si `can_reply?` false (ventana 24h) |
| B-NEW-40 | 🔴 P0 prod | Sí | ✅ WA templates: `findComponentByType is not defined` → sin inputs + crash al enviar |

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

### B-NEW-19 — Pivot muestra Nombre/Puesto = 0 + KPI ≠ suma agentes

**Severidad:** Alta (producción) — con `pivot.column_attribute` la tabla
“Resumen de agentes” listaba 7 filas pero **Nombre** y **Puesto** salían `0`.
Además el KPI Conversaciones (cuenta) no coincidía con la suma de la tabla
(faltaba bucket sin asignar).

**Síntoma:**

1. Pivote por CA (p.ej. Tipo de conversación): filas de agente OK en cantidad
   (B-NEW-13) pero identidad en `0`.
2. KPI Conversaciones = 8; suma tabla agentes = 2 (solo asignadas).

**Causa raíz:**

1. `build_pivot_rows` setea `:name`/`:rank` (symbol) y luego
   `expanded_columns.each { row[col] = 0 if nil }` con strings → JSON queda `0`.
2. Tabla agrupa por `assignee_id`; `nil` no tenía fila.

**Fix aplicado:**

1. Keys string + no rellenar columnas de identidad.
2. Fila sintética `UNASSIGNED_AGENT_ID = 0` (“Sin asignar”) en plano y pivote.
3. Copy EN/ES: Conversaciones (cuenta) vs (asignadas); hints de filtro status.
4. Smoke: assert name/rank ≠ 0 + fila unassigned.

**Archivos:**

- `app/services/reports/panel_runner_service.rb`
- `tmp/smoke_pivot_agent_rows.rb`
- `config/locales/en.yml`, `es.yml`
- `app/javascript/dashboard/i18n/locale/{en,es}/report.json`

**Migración BD:** no.

**Cómo probar:**

1. Panel con pivote → Nombre/Puesto reales.
2. Plano: suma Conversaciones (agentes + Sin asignar) ≈ KPI.
3. Smoke: `rails runner tmp/smoke_pivot_agent_rows.rb`.

**Estado:** ✅ Fijado 2026-07-24 en `fix/report-panels-pivot-identity`.

### B-NEW-20 — Aggregation / flat CA measures truncaban el universo

**Severidad:** Alta (producción) — métricas `source: aggregation` y columnas
`ca:*__sum` / `__count` en summary plano no coincidían con
`conversations_count` ni con el pivot (mismo panel / rango).

**Síntoma:**

1. KPI / Count de conversaciones = N (completo vía ReportBuilder).
2. Sum(ventas) / Count(attr) mucho más bajo o sesgado a conversaciones viejas.
3. Pivot (ya full-scan) ≠ flat CA measure en el mismo rango.

**Causa raíz:**

1. Aggregation: `.limit(100)` al cargar conversaciones.
2. Flat CA: `reorder(:id).limit(2000)` — mismos IDs tempranos que B-NEW-13.
3. Date-attribute charts: `limit * 5` sobre `updated_at`.

**Fix aplicado:**

1. `each_conversation_in_batches` (mismo patrón que pivot) para aggregation,
   flat CA por dimensión/label, y rangos por CA date.
2. Contacts aggregation: `DISTINCT contact_id` sin tope artificial.
3. Detail tables: caps `DETAIL_*_LIMIT` + flag `truncated` cuando rows < total.
4. Smoke: `tmp/smoke_panel_full_scan.rb`.

**Archivos:**

- `app/services/reports/panel_runner_service.rb`
- `app/models/saved_report_panel.rb`
- `tmp/smoke_panel_full_scan.rb`
- `docs/REPORT_PANELS.md`

**Migración BD:** no (fase 1). Ver también `date_attribute` (fase 3).

**Cómo probar:**

1. Seed demo: `tmp/seed_report_panels_demo.rb`.
2. Smoke: `rails runner tmp/smoke_panel_full_scan.rb` → `ok`.
3. UI: métrica aggregation Sum(ventas) ≈ suma de `ca:ventas__sum` en summary.

**Estado:** ✅ Fijado 2026-07-24 en `fix/report-panels-correctness`.

### B-NEW-21 — Panel date_attribute + NumericParser + UX filtros

**Severidad:** Media — semántica de fechas/metadatos y parseo inconsistente
hacían que “ventas del mes” o Sum con `"1.000,50"` no cuadraran.

**Fix aplicado (mismo branch `fix/report-panels-correctness`):**

1. `date_attribute` en `saved_report_panels` (`""` = created_at, `ca:key` = CA date).
2. `CustomAttributes::NumericParser` compartido (runner + fórmulas).
3. Sum/Avg saltan no-parseables; Count = atributo presente.
4. UI: selector fecha del panel; banner filtros mixtos; “Mostrando N de M”;
   hint contact_ca lifetime.

**Smokes:** `tmp/smoke_numeric_parser.rb`, `tmp/smoke_panel_date_attribute.rb`.

**Migración:** `20260724190000_add_date_attribute_to_saved_report_panels.rb`.

**Estado:** ✅ Fijado 2026-07-24.

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

### B-NEW-14 — Business rules, time automations, multi_list

**Feature (2026-07-23).** Guardrails in account `settings.business_rules` via
`Conversations::BusinessRulesGuard`; time automations with
`event_name: time_triggered` + `schedule` jsonb +
`Automations::TimeBasedSchedulerJob` (from `TriggerScheduledItemsJob`);
custom attribute `multi_list` (display type 9) with JSON array values and
`contains` filters.

**Migración:** `20260723210000_add_schedule_to_automation_rules.rb`

**Cómo probar:** Settings → Conversation Workflow (activate guard preset) →
status change blocked with alert; Automations → By time tab + preset;
Custom Attributes → Multi-select list → filter contains.

**i18n ES (2026-07-23):** `es/businessRules.json` + tabs/schedule en
`es/automation.json` + `MULTI_LIST` en `es/attributesMgmt.json`. UI locale ES
debe mostrar copy en español (rebuild Vite local).

**B-NEW-16 (ledger order + window_id, 2026-07-23):**
`TimeBasedRuleRunner` claimed Redis before `conditions_match?`, burning the
~90d ledger when filters failed. Order is now conditions → claim → actions.
Hours `window_id` no longer uses `last_activity_at` (label/assign churn);
it uses `time_rule_message_id` + `time_rule_message_at` from the same
`latest_messages` join as the SQL scope.

**B-NEW-17 (CRM P0 unlock on B-NEW-14/16, 2026-07-23):**
Time-triggered FE actions now include
`update_conversation_custom_attribute` /
`update_contact_custom_attribute`. Relative date CA values use Liquid via
`MessageRendererService` + `LiquidFilters::DateFilter`:
`{{ date.today }}`, `{{ date.today | plus_days: N }}`,
`{{ date.today | minus_days: N }}` (DateDrop `days_from_now`/`days_ago`
cannot take Liquid args — use the filters). `days_since_attribute` SQL
skips non-ISO strings instead of raising. Preset `seguimiento_30d` +
Index defaults `status=open` when schedule `attribute_key` is blank.

**B-NEW-18 (smoke VPS attrs → local Docker, 2026-07-24):**
Imported prod DFIT conversation CAs (`fecha_seguimiento`, `fecha_venta`, …)
into local account 1. Seed conv **#154** open with `fecha_seguimiento` ≈ 35d
ago. Upserted active time rule `Seguimiento 30d (smoke DFIT)` (id **9**):
`days_since_attribute` on `fecha_seguimiento` / 30d → `send_message` +
`update_conversation_custom_attribute` (`{{ date.today }}`) +
`notify_assignee`. `TimeBasedRuleRunner` fired: outgoing msg **#1319**,
CAs updated `2026-06-19` → `2026-07-24`, no exception. Preset defaults now
use prod keys `fecha_seguimiento` / `fecha_venta` (alias `ultimo_seguimiento`
is local-only).

### B-NEW-15 — Flows menu no visible (local / prod) — secundario

**Estado:** ✅ portado (2026-07-24) sobre `feat/business-rules-time-multilist`.
Traído desde `feat/conversation-flows`: modelos `Flow`/`FlowRun`/`FlowEvent`,
API, store/rutas FE, Sidebar **Flows**, flag `flows_v1`, acción automation
`enter_flow`. Business-rules UI/servicios intactos. Activar por cuenta:
`Account.find(1).enable_features!('flows_v1')`. UI: rebuild Vite/Docker assets
si el menú no aparece tras restart Rails.

### B-NEW-22 — Flows: columna infinita + nota handoff con IDs técnicos

**Síntoma:** el editor listaba todos los pasos en una columna; con muchas ramas
era confuso. La nota privada de handoff volcaba IDs
(`handoff_n1784…_boton3`) en lugar del camino del cliente.

**Fix (2026-07-24):**
1. `Flows::HandoffService` — resumen legible: motivo + camino con preview de
   mensaje y botón elegido (trail `matched` + `buttons[].title`).
2. `buildGraph` — `HANDOFF_REASON` usa el **title** del botón.
3. Editor canvas: `FlowCanvas.vue` (`@vue-flow/core` + dagre TB), acciones en
   `FlowProperties.vue`. Contrato `buildGraph`/`nodeToStep` intacto.

**Archivos:** `handoff_service.rb`, `Edit.vue`, `FlowCanvas.vue`,
`FlowStepNode.vue`, `FlowTerminalNode.vue`, `FlowProperties.vue`,
`en.yml` (`flows.handoff_note.*`), `en/flows.json`.

**Cómo probar:**
1. Settings → Flows → editar: canvas con edges por botón; click → panel derecho.
2. Flujo con handoff → nota privada sin IDs; camino tipo
   `"¿Qué necesitas?" → chose "Botón 3"`.
3. Rebuild Vite/Docker assets para ver el canvas.

### B-NEW-23 — Flows editor polish (layout / botones / perf)

**Síntoma:** panel derecho mezclaba meta del flow + exit + paso; 3 slots de
botones siempre visibles; canvas lento por fitView/re-layout al tipear.

**Fix (2026-07-24):**
1. Layout full-bleed: canvas + `FlowStepInspector` derecha + `FlowFooter` abajo
   (exit policy colapsable).
2. Toggle Wait for reply + add/remove botones (máx. 3); default off.
3. Nombre de nodo (`data.title`) editable en canvas/inspector.
4. Handles por botón + flechas; fitView solo al cargar/add/remove step;
   debounce content sync; sin MiniMap.

**Cómo probar:** Settings → Flows → editar: canvas amplio, footer con Save,
toggle botones, renombrar nodo, conectar desde handle de botón.

### B-NEW-24 — Flows: Activo/categoría/exit drawer/inspector

**Síntoma:** Activo en el editor; exit policy comía el canvas; delay duplicado;
toolbar del mensaje se desbordaba; sin categoría.

**Fix (2026-07-24):**
1. Switch Activo en la lista (`FlowsTableRow`); quitado del header.
2. Columna `flows.category` + input en header + columna en lista.
3. Exit rules vía Dialog drawer desde el header (canvas `min-h-[50vh]`).
4. Inspector: sin delay duplicado; secciones Actions/Buttons; overflow en editor.
5. Nodos TB más compactos con chips de botón visibles.

**Cómo probar:** lista toggle activo; editar categoría; Exit rules no tapa canvas;
configurar botones sin scroll infinito de delay doble.

### B-NEW-25 — Flows: acciones montadas + dropdown roto en inspector

**Síntoma:** Acciones del paso se veían apiladas sin número/borde; al abrir el
select aparecía un input de búsqueda suelto con el trash (dropdown clipado por
`overflow-hidden` del wrapper).

**Fix (2026-07-24):**
1. Cada acción en card con label `Action {n}` + trash en header (como botones).
2. Quitado `overflow-hidden` del wrapper de acciones; dropdowns visibles.
3. `dropdown-max-height` acotado en el inspector estrecho.

**Cómo probar:** editar paso con varias acciones → cards numeradas; abrir
“Add label” / tipo de acción → menú usable, sin fila de búsqueda fantasma.

### B-NEW-26 — Flows: acciones horiz., tipos únicos, panel izq, i18n

**Síntoma:** acciones apiladas vertical; tipo repetible; menubar de texto oculto;
dropdown limitado a ~3 opciones; header desalineado; strings EN en UI ES;
inspector a la derecha.

**Fix (2026-07-24):**
1. Acciones horizontales (como Automatizaciones) + menubar ProseMirror visible.
2. Tipo de acción único por paso (filtro en select + add deshabilitado).
3. `dropdown-max-height: max-h-80`; panel config a la izquierda / canvas a la derecha.
4. Header botones alineados con `items-end`; `es/flows.json` sincronizado.

**Cómo probar:** layout L/R; añadir 2× “Add label” bloqueado; menú con muchas
opciones; editor de mensaje con toolbar; textos ES en header/inspector.

### B-NEW-28 — Login 500 post-merge 4.16.1 (`feature_api_and_webhooks?`)

**Severidad:** P0 prod — `/auth/validate_token` 500; dashboard no entra.

**Causa:** merge upstream con `-X ours` en `config/features.yml` omitió los
flags de `feature_flags_ext_1` (incl. `api_and_webhooks`).

**Fix:** append flags ext_1 (orden upstream) + jbuilder usa
`api_and_webhooks_enabled?` + `Message.unscoped` en time-based DISTINCT ON.

**Deploy:** merge a `develop` + GHCR redeploy. Sin migración.

### B-NEW-29 — Dashboard JS roto post-4.16.1 (`hasFilteredUnreadCounts` / `useI18n`)

**Severidad:** P0 prod — login OK pero sidebar/commandbar crash; UI incompleta.

**Causa:** merge `-X ours` dejó usos de `hasFilteredUnreadCounts` / `hasDataImport`
sin definir, y `useAgentsList.js` sin imports de `vue` / `vue-i18n`.

**Fix:** definir computeds + `UNREAD_COUNT_FOR_FILTERS` en featureFlags + imports.

**Deploy:** merge PR + GHCR rebuild (assets en imagen).

### B-NEW-30 — `toggle_status` 500 (resolve / reopen / pending / snooze)

**Severidad:** P0 prod — cualquier cambio de estado vía
`POST .../conversations/:id/toggle_status` devolvía 500
(account 2 / conv 929 en `inbox.paluhub.com`).

**Causa:** `status_change_activity` pasaba `content_attributes:` a
`activity_message_params`, pero el helper solo aceptaba `content` →
`ArgumentError` en Ruby 3 dentro de `after_update_commit`. No es business
rules (esas serían 422).

**Fix:**
- `ActivityMessageHandler#activity_message_params(content, content_attributes: nil)`
  mergea `content_attributes` cuando está presente.
- Modal resolve: inputs `currency` / `percent`; pickers excluyen CAs con
  `formula`.
- `BusinessRulesGuard`: `config` no-Hash → `{}` (evita 500 con settings corruptos).

**Archivos:**
- `app/models/concerns/activity_message_handler.rb`
- `app/services/conversations/business_rules_guard.rb`
- `ConversationResolveAttributesModal.vue`, `constants.js`
- `useConversationRequiredAttributes.js`, `ConversationRequiredAttributes.vue`,
  `BusinessRuleForm.vue`

**Cómo probar:** resolve → reopen → pending → snooze sin 500; activity
message en timeline; si hay required `currency`/`percent`, modal los
edita. Local: `.\scripts\dev-up.ps1` (Vue en imagen). Prod: merge
`develop` + GHCR redeploy (sin migración).

### B-NEW-31 — Business rules: contact attrs + zero-as-blank + TYPE_HELP

**Feature.** Guardrails pueden exigir atributos de **conversación y contacto**.
En `number`/`currency`/`percent`, el valor `0` cuenta como vacío. El form
muestra `TYPE_HELP` por tipo de regla. Al resolver, el modal pide ambos
modelos y guarda contacto vía `contacts/update` antes de `toggle_status`.

**Archivos:**
- `Conversations::BusinessRulesGuard`
- `BusinessRuleForm.vue`, `useConversationRequiredAttributes.js`
- `ConversationResolveAttributesModal.vue`, `ResolveAction.vue`
- `en/es/businessRules.json`

**Cómo probar:** Settings → Business rules → exigir CA de contacto +
condicional `tipo=venta` → currency; resolve con `0` bloquea; valor > 0 OK.
Local: `up -d --build` (Vue en imagen).

### B-NEW-32 — Business rules UX: ConditionRow + categorías + multi-status

**Feature.** Guards usan `conditions[]` (mismos filtros que Automations via
`ConditionRow`), pueden exigir attrs por **categoría**, y el pre-check FE
cubre resolve/pending/open (forbid/assignee/nota vía alert). Las reglas por
tiempo siguen solo en **Automations** (`time_triggered`), no en Business rules.

**Archivos:**
- `BusinessRules::ConditionsMatcher`, `RequiredAttributeKeys`, Guard
- `BusinessRuleForm.vue`, `AttributeRequirementPicker.vue`, Index
- `useBusinessRulesStatusGuard.js`, ResolveAction / ChatList / bulk

**Cómo probar:** form Cuando/Entonces; categoría Venta exige keys nuevas;
resolve modal; pending con require_reason. Local: `--build`.

### B-NEW-33 — Dialog Business rules: clic en filtro guardaba la regla

**Causa:** `Dialog` usa `<form @submit>` y `MultiSelect` / trash / “Añadir
condición” renderizaban `<button>` sin `type="button"` → submit al abrir
estados (multiSelect).

**Fix:** `type="button"` en `MultiSelect.vue`, `ConditionRow.vue`,
`BusinessRuleForm.vue`.

**Cómo probar:** editar regla → condición Status → abrir valores; el modal
no debe cerrarse ni guardar.

### B-NEW-34 — Motivo al posponer: FE bloqueaba nota y snooze sin error

**Causa:** pre-check FE marcaba `needsPrivateNote` sin mirar mensajes →
pending nunca llegaba al Guard. Snooze vía cmdbar no formateaba 422 de BR.

**Fix:** defer nota privada al API; snooze pre-check + `formatBusinessRuleError`;
si falta CA de motivo al posponer desde ResolveAction, modal → luego picker.

**Cómo probar:** preset motivo (solo nota) → pending sin nota → alert API;
añadir nota privada → pending OK. Snooze sin nota → alert legible.

### B-NEW-35 — Automation por tiempo + regla “motivo al posponer” chocaban

**Causa:** `BusinessRulesGuard` corre en todo `will_save_change_to_status?`.
Una automation (`snooze_conversation` / `pending`) no llena motivo/nota →
`RecordInvalid` tragado por `AutomationRules::ActionService` → mensaje sí,
posponer no.

**Fix:** si `Current.executed_by` es `AutomationRule`, el Guard retorna OK
(candados para agentes; robots no). Macros / UI agent siguen validados.

**Archivo:** `app/services/conversations/business_rules_guard.rb`

**Cómo probar:** regla motivo en snoozed + automation “tras N min → snooze +
mensaje” → conversación queda snoozed y mensaje enviado. Agente snooze
sin motivo → sigue bloqueado.

### B-NEW-36 — Exigir agente + dropdown contacto transparente

**Causa (assignee):** FE trataba `meta.assignee` (incluye bot del canal) como
válido → la regla nunca pedía humano. Backend ya miraba `assignee_id` (User).

**Fix:** FE usa `isHumanAssigneeMeta` o team; copy aclara “humano / bot no cuenta”.

**Causa (UI):** `animate-pulse` en Sin asignar anima opacity → stacking context
+ menú `bg-n-alpha` → Acciones de conversación se ven a través del dropdown.

**Fix:** quitar pulse; menú con fondo sólido + `z-50` al abrir en
`OutlinedSelectField`.

**Archivos:** `useBusinessRulesStatusGuard.js`, `ContactAssigneeSelector.vue`,
`OutlinedSelectField.vue`, i18n businessRules.

**Cómo probar:** inbox con bot, conversación solo-bot, regla exigir al abrir →
bloquea hasta asignar humano/equipo. Contacto sin agente → abrir selector →
lista legible opaca.

### B-NEW-37 — Post-compra: atributo de fecha era texto libre

**Causa:** `days_since_attribute` usaba `<input>` para `schedule.attribute_key`.

**Fix:** select con CAs de conversación tipo `date` y `datetime` (display name).
Claves huérfanas de reglas viejas siguen visibles. Datetime ya castea por
día calendario (`LEFT(..., 10)::date` en el runner).

**Archivos:** `AutomationRuleForm.vue`, i18n automation EN/ES,
`time_based_rule_runner.rb` (comentario).

**Cómo probar:** Automations → time triggered / preset post-compra →
dropdown lista fechas; datetime marcado; sin CAs de fecha → mensaje vacío.

### B-NEW-38 — Automation: nota privada de auditoría al ejecutarse

**Causa:** time/event rules podían correr sin rastro visible (solo Redis ledger /
acciones mudas).

**Fix:** tras las acciones configuradas, `AutomationRules::ActionService` siempre
deja una nota privada corta vía `Conversations::SystemAuditNote`
(`system_audit: true`, `automation_rule_id`). Flows fuera de alcance.

**Archivos:** `system_audit_note.rb`, `automation_rules/action_service.rb`,
`en.yml` / `es.yml` (`automation.audit_note`), `docs/BUGS.md`.

**Cómo probar:** disparar cualquier automation (o time rule) → timeline muestra
«Automatización «…» ejecutada.» como nota privada.

### B-NEW-39 — Automation: no enviar si ventana Meta/WhatsApp cerrada

**Causa:** `send_message` / attachment creaban outbound que WA marcaba failed
fuera de la ventana 24h (Messenger/IG similar vía `can_reply?`).

**Fix:** antes de enviar (inmediato o `DeferredOutboundJob`), si
`conversation.can_reply?` es false → no crear mensaje público; dejar nota
privada (`messaging_window_skipped`) + la auditoría B-NEW-38 al final.

**Archivos:** `automation_rules/action_service.rb`,
`messages/deferred_outbound_job.rb`, `en.yml` / `es.yml`, `docs/BUGS.md`.

**Cómo probar:** conversación WA sin incoming reciente → automation con
`send_message` → sin bubble al cliente; sí nota de ventana cerrada + audit.

### B-NEW-40 — Plantillas WA: sin inputs de variables + ReferenceError al enviar

**Severidad:** P0 prod — modal de plantillas inutilizable (con o sin variables).

**Síntoma:**
- Plantilla con `{{contact_name}}` (ej. `ventas_seguimiento`): preview OK, mensaje
  “rellene todas las variables”, **sin inputs**, Send clickeable.
- Plantilla sin variables: al Enviar →
  `ReferenceError: findComponentByType is not defined` (`templateHelper.js`).

**Causa:** tras el refactor `@chatwoot/utils` (#15001) + merge, `templateHelper.js`
hacía `export { findComponentByType, ... } from '@chatwoot/utils'` (re-export)
pero las funciones locales (`buildTemplateParameters`,
`buildTemplateButtonsSnapshot`) llamaban `findComponentByType` **sin importarlo
al scope del módulo**. En ES modules el re-export no define el binding local →
crash en init (params vacíos) y en send (snapshot).

**Fix:**
- Import local de `findComponentByType`, `COMPONENT_TYPES`, `MEDIA_FORMATS`.
- `buildTemplateParameters` delega a `buildWhatsAppProcessedParams`.
- Parser: init sin 2º arg obsoleto.

**Archivos:** `helper/templateHelper.js`, `WhatsAppTemplateParser.vue`.

**Cómo probar:** abrir `ventas_seguimiento` → input `contact_name`; rellenar y
enviar. Plantilla sin vars → Enviar sin error en consola.

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
