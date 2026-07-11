# Bugs abiertos y fixes aplicados — fork PaluHub (Chatwoot)

> Documento vivo. Cada bug tiene ID, severidad, archivo, descripción, fix aplicado
> y cómo probarlo. Trazabilidad cruzando con `INTERNAL_TASKS_AND_ALERTS.md`.

**Última actualización:** generado durante sesión de revisión del branch
`feat/internal-tasks` (PR #3).

---

## 1. Resumen de fixes aplicados (sesión 2026-07-11)

| ID | Severidad | Archivo | Estado |
|----|-----------|---------|--------|
| TASK-001 | Alta | `app/services/conversations/timeline_builder.rb` | ✅ Fijado |
| TASK-002 | Alta | `app/javascript/dashboard/routes/dashboard/tasks/TaskView.vue` | ✅ Fijado |
| TASK-003 | Media | `app/services/internal_tasks/claim_service.rb` | ✅ Fijado |
| TASK-004 | Media | `app/models/internal_task.rb` | ✅ Fijado |
| TASK-005 | Baja | `app/javascript/dashboard/components-next/InternalTasks/TaskDetail.vue` | ✅ Fijado (cleanup) |
| UX-001 | Media | `ReplyBox.vue` | ✅ Reply preview en notas privadas |
| UX-002 | Media | `WhatsAppTemplateParser` + `Text/Index.vue` | ✅ Snapshot botones plantilla WA en bubble |

---

## 2. Fijados en esta sesión

### TASK-001 — Notas privadas filtradas en timeline (privacidad)

**Severidad:** Alta — bug de privacidad.

**Archivo:** `app/services/conversations/timeline_builder.rb`

**Problema:** El método `can_view_private_notes?` retornaba `true` hardcodeado.
Cualquier agente en la cuenta podía ver las notas privadas de otros al abrir el
timeline de una conversación.

**Fix aplicado:** reglas conservadoras hasta que exista una `NotePolicy` oficial:

1. Admin de la conversación: ve todas las notas privadas.
2. Autor de la nota: ve siempre su propia nota.
3. Asignado o miembro del equipo de la conversación: ve notas para contexto.
4. Resto: NO ve.

```ruby
def can_view_private_notes?(message)
  return false if user.blank?
  return false if message.account_id != conversation.account_id

  account_user = conversation.account.account_users.find_by(user_id: user.id)
  return true if account_user&.administrator?

  return true if message.sender_id == user.id

  assigned = conversation.assignee_id == user.id
  on_team = conversation.team_id.present? && user.teams.exists?(id: conversation.team_id)
  assigned || on_team
end
```

**Cómo probar:**
- Agente A crea nota privada en conversación.
- Agente B (mismo equipo, no asignado) abre `/conversations/:id/timeline`.
- Antes: veía la nota. Ahora: NO la ve.
- Admin sigue viendo todo.
- Agente asignado a la conversación SÍ ve notas.

**Riesgo residual:** Otros lugares que rendericen timeline (ej. componente de
notificaciones) podrían tener reglas distintas. Revisar `app/views/api/v1/...`
jbuilders que filtran `private?`.

---

### TASK-002 — `dispatch('clearSelectedState')` roto al salir de /tasks

**Severidad:** Alta — error en consola en navegación básica.

**Archivo frontend:** `app/javascript/dashboard/routes/dashboard/tasks/TaskView.vue`
**Archivo store:** `app/javascript/dashboard/store/modules/internalTasks.js`

**Problema:** `onBeforeRouteLeave` llamaba `store.dispatch('clearSelectedState')`
que **no existía** en el módulo `internalTasks`. La acción vivía en `conversations`.
Vuex no limpia nada, queda `selectedTaskRecord` en memoria.

**Fix aplicado:**
- Nueva mutation `CLEAR_INTERNAL_TASKS_SELECTED` en `internalTasks.js`.
- Nueva action `clearSelectedState` que hace `commit(CLEAR_INTERNAL_TASKS_SELECTED)`.
- `TaskView.vue` ahora usa namespace: `dispatch('internalTasks/clearSelectedState')`.

```js
clearSelectedState({ commit }) {
  commit(CLEAR_SELECTED_TASK);
}

[CLEAR_SELECTED_TASK](_state) {
  _state.selectedTaskRecord = null;
}
```

**Cómo probar:**
1. Ir a `/app/accounts/1/tasks/5` (detalle).
2. Volver a otra página (ej. Conversations).
3. Abrir devtools console → no debe haber warning "unknown action type".
4. Volver a `/tasks` → estado limpio, sin datos stale.

---

### TASK-003 — `ClaimService` lanza `StandardError` genérico

**Severidad:** Media — UX confusa en race condition.

**Archivos:**
- `app/services/internal_tasks/already_claimed_error.rb` (nuevo)
- `app/services/internal_tasks/claim_service.rb`
- `app/controllers/api/v1/accounts/internal_tasks_controller.rb`

**Problema:** Si dos agentes reclaaman la misma task simultáneamente, el segundo
recibía un error 500 en vez de un 409 Conflict semántico. El error genérico
no se podía capturar ni traducir en el frontend.

**Fix aplicado:**
1. Nueva clase `InternalTasks::AlreadyClaimedError` (hereda de `StandardError`,
   expone el task afectado).
2. `ClaimService` la lanza en vez de `StandardError`.
3. Controller usa `rescue_from` para devolver 409 con JSON estructurado:

```ruby
# app/controllers/api/v1/accounts/internal_tasks_controller.rb
rescue_from InternalTasks::AlreadyClaimedError, with: :render_already_claimed

private

def render_already_claimed(error)
  render json: {
    error: 'task_already_claimed',
    message: I18n.t('tasks.errors.already_claimed', default: 'Task already claimed by another user'),
    task_id: error.task.id
  }, status: :conflict
end
```

**Cómo probar:**
- Agente A hace POST `/internal_tasks/5/claim`.
- Agente B hace lo mismo antes que A recargue.
- B recibe 409 con `error: 'task_already_claimed'` (en vez de 500).

---

### TASK-004 — `depends_on_task_id` cross-account

**Severidad:** Media — vector de cross-tenant data leak.

**Archivo:** `app/models/internal_task.rb`

**Problema:** El campo `depends_on_task_id` no validaba que la tarea dependiente
pertenezca a la misma cuenta (`account_id`). Un agente con acceso a IDs internos
podría crear dependencias entre cuentas.

**Fix aplicado:** nueva validación `depends_on_belongs_to_account`:

```ruby
validate :depends_on_belongs_to_account

def depends_on_belongs_to_account
  return if depends_on_task_id.blank?

  errors.add(:depends_on_task_id, 'must belong to the same account') if depends_on_task&.account_id != account_id
end
```

**Cómo probar:**
- Crear task A en cuenta 1.
- Crear task B en cuenta 2.
- PATCH a task B con `depends_on_task_id: A.id`.
- Antes: se guardaba.
- Ahora: 422 con mensaje "depends_on_task_id must belong to the same account".

---

### TASK-005 — Import muerto en TaskDetail.vue

**Severidad:** Baja — code smell.

**Archivo:** `app/javascript/dashboard/components-next/InternalTasks/TaskDetail.vue`

**Problema:** `const currentChat = useMapGetter('getSelectedChat')` se declaraba
pero nunca se usaba en el script ni en el template.

**Fix aplicado:** línea eliminada.

---

## 3. Fixes verificados (estaban aplicados según docs)

Estos fixes estaban documentados en `INTERNAL_TASKS_AND_ALERTS.md` y se
verificaron que siguen presentes:

| ID | Fix | Verificado en | Estado |
|----|-----|---------------|--------|
| AUDIO-001 | Audio init cuando `audio === null` o tone cambia | `app/javascript/dashboard/helper/AudioAlerts/DashboardAudioNotificationHelper.js:96` | ✅ OK |
| AUDIO-002 | Null-guard en `playAudioAlert` | línea 53 | ✅ OK |
| AUDIO-003 | Permission flag `hasSentSoundPermissionsRequest` en `audioConfig` | línea 41 | ✅ OK |
| CABLE-001 | `PRESENCE_INTERVAL = 60000` (60s cliente) | `app/javascript/shared/helpers/BaseActionCableConnector.js:3` | ✅ OK |
| CABLE-002 | `visibilitychange → reopen()` + presence ping | línea 58, 68 | ✅ OK |
| CABLE-003 | `PRESENCE_DURATION` default 90 | `lib/online_status_tracker.rb:3` | ✅ OK |

---

## 4. Out of scope (del doc oficial, NO tocado)

Lo que `INTERNAL_TASKS_AND_ALERTS.md` lista como follow-ups queda sin tocar en
esta sesión:

- Kanban drag-and-drop
- Cambiar default de `enable_audio_alerts` away from `none`
- Patch ActionCable `staleThreshold` en `node_modules`
- Instagram OAuth POST token fix

---

## 5. Bugs abiertos (TODAVÍA no arreglados)

| ID | Descripción | Severidad | Workaround |
|----|-------------|-----------|-----------|
| TASK-006 | `BotInboxMenuEditor` inline en `page.tsx:983-1278` es código muerto (sección 10 de `ASSISTANT_CONFIG.md`) | Baja | Borrar |
| TASK-007 | Emoji mojibake `ðŸŒŽ` en `ContactInfo.vue` (fallback cuando no hay countryCode) | Baja | Reemplazar por icono Lucide |
| TASK-008 | `task_templates.position` sin índice en migración `20260709120000` | Baja | Añadir `add_index :task_templates, [:account_id, :position]` |

Estos no se arreglaron en esta sesión para mantener el diff mínimo.

---

## 5b. UX fijados (reply / plantillas WA)

### UX-001 — Preview reply-to oculto en notas privadas

**Archivo:** `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue`

**Problema:** `shouldShowReplyToMessage` exigía `!isPrivate`, así que al abrir nota
privada desde el menú del mensaje el banner `ReplyToMessage` no se montaba.

**Fix:** si `isOnPrivateNote` y hay `inReplyTo.id`, mostrar el preview (sin exigir
feature de canal `REPLY_TO`).

### UX-002 — Botones de plantilla WhatsApp no visibles tras enviar

**Archivos:** `WhatsAppTemplateParser.vue`, `helper/templateHelper.js`
(`buildTemplateButtonsSnapshot`), `bubbles/Text/Index.vue`, compose helpers.

**Problema:** al enviar solo iba el body + `template_params`; los botones llegaban
a Meta pero no se persistían para la UI del agente.

**Fix:** snapshot `content_attributes.template_buttons` al enviar; el bubble Text
lista labels + URL/phone/copy-code. Mensajes viejos sin snapshot: sin botones.

---

## 6. Cómo probar los fixes (smoke test)

```powershell
# Backend (Ruby) — restart basta
docker compose -f docker-compose.dokploy.yml -f docker-compose.dokploy.fork.yml restart chatwoot-rails

# Frontend (Vue) — rebuild obligatorio (assets baked in image)
docker compose -f docker-compose.dokploy.yml -f docker-compose.dokploy.fork.yml up -d --build chatwoot-rails
```

**Tests manuales sugeridos:**

1. `TASK-002`: navegar entre `/tasks/5` y otra página, revisar DevTools console.
2. `TASK-001`: abrir timeline como agente no-asignado, contar notas privadas visibles.
3. `TASK-003`: dos browsers, mismo user_id, click "claim" simultáneamente.
4. `TASK-004`: intentar crear dependencia cross-account vía API.
5. `TASK-005`: levantar DevTools, verificar que no hay warning de variable no usada.

**UX (reply / templates):**

6. Menú mensaje → nota privada → el editor debe mostrar el mismo preview de reply-to que un reply público.
7. Enviar plantilla WhatsApp con botones/URL/phone → bubble del agente muestra body + labels/links resueltos (mensajes viejos sin snapshot: solo body).

---

## 7. Próximos pasos (recomendado)

1. Mergear rama actual → `develop`.
2. Correr `bundle exec rspec spec/services/internal_tasks/ spec/services/conversations/timeline_builder_spec.rb` (crear specs primero si no existen).
3. Una vez mergeado, redeploy GHCR → Dokploy staging.
4. Smoke test en `test.inbox.paluhub.com` antes de promover a producción.
5. Cuando esté estable, promociones a producción siguiendo
   `docs/PRODUCTION_MIGRATION.md`.

---

## 8. Cambios a documentación relacionada

- `AGENTS.md`: agregar sección `Fixes recientes` linkando a este archivo.
- `INTERNAL_TASKS_AND_ALERTS.md`: agregar entrada sobre los TASK-001..005.
- Si se decide crear `NotePolicy`, vincular desde TASK-001.
