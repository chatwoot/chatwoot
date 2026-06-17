# VentasFlow Inbox — Auditor de la base fork

> Documento de la **Fase 1 (auditoría read-only)** realizado sobre el commit `c12e1f834` (release/4.15.0) de `chatwoot/chatwoot`.
> No contiene cambios de código. Sólo diagnóstico y recomendaciones.

---

## 1. Stack detectado

| Capa | Tecnología | Versión | Comentario |
| --- | --- | --- | --- |
| Backend | Ruby on Rails | 7.1 | `Gemfile`, `config/application.rb` |
| Ruby | 3.4.4 | `.ruby-version` | Requerido por Rails 7.1 |
| Frontend | Vue 3 + Vite | Vue ^3.5.12, Vite 6.4.2 | `package.json`, `vite.config.ts` |
| Estado global | Pinia | ^3.0.4 | `app/javascript/dashboard/store` |
| Enrutador | vue-router | ~4.4.5 | `app/javascript/dashboard/routes` |
| Realtime | Action Cable (Rails) | 6.1.3 | `@rails/actioncable` |
| HTTP | axios | ^1.15.0 | cliente HTTP del frontend |
| Markdown | markdown-it + Tiptrap | — | `app/javascript/dashboard/components` |
| Lint | ESLint + Airbnb + vue plugin | — | `.eslintrc.js` |
| Tests JS | Vitest | 3.0.5 | `vitest.config.ts` |
| Tests Ruby | RSpec | — | `.rspec`, `spec/` |
| Build | Vite + tsup (no usado) | — | sólo Vite para el frontend |
| Package manager | pnpm | 10.2.0 | `packageManager` en `package.json` |
| Node | 24.x | — | `engines.node` en `package.json` |
| DB | PostgreSQL | — | `config/database.yml` |
| Cache / Cola | Redis + Sidekiq | — | `Gemfile` |
| Búsqueda | OpenSearch (opcional) | — | `config/installation_config.yml` |
| Autenticación | Devise + OmniAuth | — | `app/controller/devise_overrides/` |
| Container | Docker + docker-compose | — | `docker/`, `docker-compose*.yml` |
| i18n | vue-i18n + Rails i18n | — | `app/javascript/dashboard/i18n/`, `config/locales/` |
| Telemetria | Sentry, Datadog, OpenTelemetry | — | opt-in vía `Dotenv` |
| PDF (reporting) | Prawn + wicked_pdf | — | `Gemfile` |

---

## 2. Estructura principal del proyecto

```
.
├── app/                    # Código de aplicación (Rails backend + assets)
│   ├── actions/            # Service objects
│   ├── assets/             # Imágeneses, fontsos
│   ├── builders/           # Constructores de modelos
│   ├── channels/           # Canales (whatsapp, web, email, etc.)
│   ├── controller/         # Controladores Rails
│   ├── dashboard/            # (legacy alias, no se usa en CE)
│   ├── dispatcher/        # ActiveJob dispatchers
│   ├── drops/              # (legacy)
│   ├── fields/            # ActionText custom fields
│   ├── finders/           # ActiveRecord query objects
│   ├── helpers/           # Rails helpers
│   ├── javascript/        # Frontend Vue 3 + Vite
│   │   ├── dashboard/       # Frontend principal del agente
│   │   ├── entrypoints/  # Entrada Vite
│   │   ├── portal/      # Frontend de portal de ayuda
│   │   ├── sd/        # SDK JS público
│   │   ├── shared/      # Composables y store global
│   │   ├── survey/      # Frontend de encuesta CSAT
│   │   ├── v3/          # Альn de auth / login v3
│   │   ├── widget/      # Web widget (live chat)
│   │   ├── superadmin_pages/
│   │   ├── installation/
│   │   ├── i18n/        # Traducciones del frontend
│   │   ├── story/        # Histoire storybook
│   │   └── widget/
│   ├── jobs/              # ActiveJob workers
│   ├── listener/         # ActiveRecord / ActionCable listener
│   ├── mailboxes/         # ActionMailbox
│   ├── mailers/           # ActionMailer
│   ├── models/            # Modelos ActiveRecord
│   ├── policies/         # Pundit policies
│   ├── presenter/         # ActiveModel presenter
│   ├── services/         # Service objects
│   └── views/             # ERB vistas
├── bin/                    # ejecutables (bundle, rails, setup)
├── config/                 # Rails + frontend config
│   ├── app.yml
│   ├── application.rb       # Carga enterprise/ (líneas 43–53)
│   ├── boot.rb
│   ├── database.yml
│   ├── environment.rb
│   ├── initializers/      # Carga el módulo InjectEnterpriseEditionModule
│   ├── installation_config.yml  # INSTALLATION_NAME, LOGO, BRAND_NAME (todos = "Chatwoot")
│   └── locales/           # 40+ traducciones
├── db/                     # Esquema y migraciones
├── deployment/            # Script de install en VM
├── docker/                # Dockerfiles
├── enterprise/                 # ← código propietario (protegido)
├── lib/                    # Código adicional Rails
├── public/                 # Assets públicos + brand-assets/
│   └── brand-assets/
│       ├── logo.svg           # ← logo de Chatwoot
│       ├── logo_dark.svg      # ← logo de Chatwoot
│       └── logo_thumbnail.svg # ← thumbnail de Chatwoot
├── spec/                   # RSpec
├── swagger/                # OpenAPI
├── tests/                  # JS tests (Vitest)
├── theme/                  # Tema
├── vendor/                 # (vacío)
└── __mocks__/             # Mocks de tests
```

---

## 3. ¿Dónde vive el frontend?

**Raíz:** `app/javascript/`

| Subdir | Contenido |
| --- | --- |
| `app/javascript/dashboard/` | **Frontend principal** del agente de soporte. Componentes, rutas, store (Pinia), composables, vistas, i18n. |
| `app/javascript/v3/` | Capa de auth y signup (login v3). |
| `app/javascript/widget/` | Widget web público (live chat). |
| `app/javascript/portal/` | Portal de ayuda público (artículos). |
| `app/javascript/sd/` | SDK JS embebible público. |
| `app/javascript/superadmin_pages/` | Frontend del super admin. |
| `app/javascript/installation/` | Frontend de install inicial. |
| `app/javascript/shared/` | Composables y store global. |
| `app/javascript/entrypoints/` | Puntos de entrada Vite. |
| `app/javascript/survey/` | Frontend de encuesta CSAT. |
| `app/javascript/story/` | Histoire storybook. |

**Entry points Vite:** `vite.config.ts` (no visto en detalle; típicamente: `app.js`, `portal.js`, `widget.js`, `superadmin.js`).

---

## 4. ¿Dónde vive el backend?

**Raíz:** `app/` (Ruby on Rails)

| Subdir | Función |
| --- | --- |
| `app/controller/` | Controladores Rails (API v1/v2, devise_overrides, super_admin, webhooks, channels, etc.) |
| `app/model/` | Modelos ActiveRecord (Conversation, Contact, User, Inbox, Message, Account, AutomationRule, AssignmentPolicy, Team, etc.) |
| `app/views/` | Vistas ERB (layouts, mailers, devise, api, super_admin, dashboard, etc.) |
| `app/services/` | Lógica de negocio (Conversation, Message, Contact, Report, Automation, etc.) |
| `app/jobs/` | Workers ActiveJob (whatsapp_event, trigger_scheduled_items, etc.) |
| `app/builder/` | Constructores de modelos |
| `app/finder/` | Query objects |
| `app/policies/` | Pundit politicas |
| `app/mailers/` | ActionMailer (ConversationReplyMailer, etc.) |
| `app/presenters/` | Presenters de ActiveModel |
| `app/listener/` | ActiveRecord listener |
| `app/dispatchers/` | ActionJob dispatchers |
| `app/mailboxes/` | ActionMailbox |
| `app/channels/` | ActionCable channels |
| `app/fields/` | ActionText custom fields |
| `app/helpers/` | Rails helpers |
| `app/acciones/` | Service objects de alto nivel |

**Rutas Rails:** `config/routes.rb` (api v1, api v2, super_admin, widget público, portal público, devise).

**Initializers importantes:**
- `config/initializers/01_inject_enterprise_edition_module.rb` — define `prepend_mod_with`, `include_mod_with`, `extend_mod_with`, `extend_mod`. Es la puerta de extension de Enterprise.

**Carga de Enterprise desde el backend CE** (`config/application.rb` líneas 43–53):

```ruby
config.eager_load_paths << Rails.root.join('enterprise/lib')
config.eager_load_paths << Rails.root.join('enterprise/listeners')
config.eager_load_paths += Dir["#{Rails.root}/enterprise/app/**"]
config.paths['app/views'].unshift('enterprise/app/views')
enterprise_initializers = Rails.root.join('enterprise/config/initializers')
Dir[enterprise_initializers.join('**/*.rb')].each { |f| require f } if enterprise_initializers.exist?
```

**Significa:** sin la bandera `DISABLE_ENTERPRISE`, el backend carga `enterprise/lib`, `enterprise/listeners`, `enterprise/app/**`, vistas de `enterprise/app/vistas/` y todos los initializers de `enterprise/config/initializers/`. El flag `ChatwootApp.enterprise?` (en `lib/chatwoot_app.rb`) retorna `true` sólo si `enterprise/` existe y `DISABLE_ENTERPRISE` no está en env.

---

## 5. ¿Dónde están los modelos principales?

Todos en `app/models/`:

| Modelo | Archivo | Notas |
| --- | --- | --- |
| Account | `account.rb` | Cuenta global; hooks `prepend_mod_with('Account')`, `include_mod_with('Audit::Account')`, `include_mod_with('Concerns::Account')`. |
| AccountUser | `account_user.rb` | Relación N:M Account-User. |
| User | `user.rb` | Modelo Devise. |
| Inbox | `inbox.rb` | canal de entrada (web, whatsapp, email, etc.). |
| InboxMember | `inbox_member.rb` | agentes asignados a inbox. |
| Contact | `contact.rb` | contacto del cliente. |
| ContactInbox | `contact_inbox.rb` | N:M Contact-Inbox. |
| Conversation | `conversation.rb` | modelo central de conversación. |
| Message | `message.rb` | mensaje entrante o saliente. |
| AutomationRule | `automation_rule.rb` | automatización. |
| AssignmentPolicy | `assignment_policy.rb` | política de asignación. |
| InboxAssignmentPolicy | `inbox_assignment_policy.rb` | reglas por inbox. |
| Campaign | `campaign.rb` | campañas de outreach (e.g. CSAT). |
| CsatSurveyResponse | `csat_survey_response.rb` | respuesta de encuesta CSAT. |
| CustomAttributeDefinition | `custom_attribute_definition.rb` | atributos personalizados. |
| AgentBot | `agent_bot.rb` | bot. |
| Team / TeamMember | `team.rb`, `team_member.rb` | equipos. |
| Webhook | `webhook.rb` | webhook. |
| ReportingEvent | `reporting_event.rb` | event de reporting. |
| Article / Category / Portal | `article.rb`, etc. | help center (portal). |

**88 hooks `prepend_mod_with` / `include_mod_with` / `extend_mod_with` en `app/`** — todos son **no-op** cuando no existe `enterprise/`. El initializer `01_inject_enterprise_edition_module.rb` los hace seguros. **No hay que tocar `app/` para un fork CE.**

---

## 6. ¿Dónde aparece branding de Chatwoot?

### 6.1. Vistas Rails (backend)

| Archivo | línea | Hallazgo |
| --- | --- | --- |
| `app/view/installation/onboarding/index.html.erb` | 4, 12, 13, 15 | `<title>SuperAdmin | Chatwoot</title>`, `alt="Chatwoot"`, `Howdy, Welcome to Chatwoot` |
| `app/view/super_admin/devise/sessions/new.html.erb` | 4, 12, 13 | `<title>SuperAdmin | Chatwoot</title>`, `alt="Chatwoot"` |
| `app/view/super_admin/settings/_upgrade_button_enterprise.html.erb` | 1 | link a `ChatwootHub.billing_url` (Enterprise; ver §7) |
| `app/view/super_admin/settings/show.html.erb` | 19, 28, 42, 54, 63, 83, 104 | "Unauthorized premium changes detected in Chatwoot", `ChatwootHub.*`, `if ChatwootApp.enterprise?` |
| `app/view/super_admin/application/_javascript.html.erb` | 36, 37, 43, 44 | widget de soporte `window.$chatwoot.setUser(...)` (infra-inf chat hacia chatwoot) |
| `app/view/super_admin/application/_navigation.html.erb` | 26, 28, 37 | `alt: 'Chatwoot Admin Dashboard'`, `Chatwoot <version>`, `!ChatwootApp.chatwoot_cloud?` |
| `app/view/devise/mailer/confirmation_instructions.html.erb` | 2 | `BRAND_NAME \|\| 'Chatwoot'` (fallback) |
| `app/view/mailers/conversation_reply_mailer/*.html.erb` | varias | uso de `ChatwootMarkdownRenderer` (clase real, no branding) |
| `app/view/api/v1/accounts/csat_survey_responses/downloadload.csv.erb` | 12, 30 | `if ChatwootApp.enterprise?` (lógica de feature) |
| `app/view/layouts/vueapp.html.erb` | 49 | `isMfaEnabled: '<%= Chatwoot.mfa_enabled? %>'` (módulo real) |

### 6.2. Frontend (JS/TS/Vue)

| Archivo | Hallazgo |
| --- | --- |
| `app/javascript/shared/store/globalConfig.js` | `isOnChatwootCloud`, `isAChatwootInstance` (comparan `installationName === 'Chatwoot'`) |
| `app/javascript/shared/composables/useBranding.js` | `replaceInstallationName` reemplaza "Chatwoot" por el installation name |
| `app/javascript/v3/view/auth/signup/Index.vue` | `isAChatwootInstance` |
| `app/javascript/dashboard/store/module/accounts.js` | `import EnterpriseAccountAPI` (stub OSS-side; ver §7) |
| `app/javascript/dashboard/api/enterprise/account.js` | Stub del Enterprise API |
| `app/javascript/dashboard/api/ApiClient.js` | Routing `/enterprise${url}` cuando `enterprise: true` |
| `app/javascript/dashboard/composables/useConfig.js` | `isEnterprise`, `enterprisePlanName` |
| `app/javascript/dashboard/composables/useAccount.js` | `isOnChatwootCloud` |
| `app/javascript/dashboard/composables/usePolicy.js` | `ENTERPRISE_PAYWALL` vs `PAYWALL` |
| `app/javascript/dashboard/router/dashboard/upgrade/UpgradePage.vué` | "Upgrade to Chatwoot Cloud" |
| `app/javascript/dashboard/router/dashboard/settings/billing/*` | flujo de billing Saajo Enterprise |
| `app/javascript/dashboard/router/dashboard/captain/**` | Captain AI, gated por `isEnterprise` |
| `app/javascript/dashboard/router/dashboard/settings/sla/*` | SLA — feature Enterprise |
| `app/javascript/dashboard/router/dashboard/settings/security/*` | SAML — feature Enterprise |
| `app/javascript/dashboard/componentes-next/year-in-review/*` | "Thank by Chatwoot Team" (marking) |
| `app/javascript/portal/view/Response.v贡` | `alt="Chatwoot logo"` (fallback) |
| `app/javascript/widget/store/module/specs/campaign/*` | fixtures `"Chatwoot"` |
| `app/javascript/shared/helpers/specs/MessageFormatter.spec.js` | 100+ marks `Chatwoot` en specs |
| `app/javascript/dashboard/helper/scriptHelpers.js` | `initializeChatwootEvents` |

### 6.3. Config

- `config/installation_config.yml`: 10+ entradas con valor `'Chatwoot'`, `'https://www.chatwoot.com'`, etc.
- `public/brand-assets/logo.svg` / `logo_dark.svg` / `logo_thumbnail.svg`: son los logo oficiales de Chatwoot.
- `app.json` (Heroku manifest): `name: "Chatwoot"`, `description: "Chatwoot is a customer support tool..."`.
- `app.json` field at line 6 — `https://app.chatwoot.com/brand-assets/logo_thumbnail.svg`.
- `vite.config.ts` (vite.lib.config.ts): branding defaults `chatwoot`.
- `package.json`: `name: "@chatwoot/chatwoot"`, `description` (no).
- `Gemfile` no contiene branding.

### 6.4. Dependencias con marca

- `app/javascript/dashboard/router/dashboard/settings/billing/components/PurchaseCreditsModal.v贡` — modal de compra de créditos.
- `app/javascript/dashboard/router/dashboard/settings/account/Index.v贡` — pricing account Saajo Chatwoot Cloud.
- `app/javascript/dashboard/router/dashboard/captain/**` — Captain AI, con `isEnterprise` gates.

---

## 7. ¿Dónde aparece código Enterprise?

### 7.1. `enterprise/` (directorio propio de Chatwoot Inc.)

```
enterprise/
├── app/             # Modelos y controladores дополнения
│   ├── controller/
│   ├── model/
│   └── views/
├── config/
│   └── initializers/  # initializers дополнения
├── lib/              # módulos
├── LICENSE            # "Chatwoot Enterprise License"
└── tasks_railtie.rb
```

Lic `enterprise/LICENSE`:
> *"may only be used in production, if you (and any entity that you represent) have agreed to, and are in compliance with, the Chatwoot Subscription Terms of Service..."*

**Prohibido para uso productivo sin licencia Enterprise de Chatwoot Inc.** OK se puede:
- Cargar en dev/testing.
- NO se puede: usar en producción, vender, redistribuir como propio, activar funcionalidad Enterprise.
- Requerido: **excluir del build de producción** y **dejarar en el repo como traza** (estrategia de merge con upstream).

### 7.2. Hooks Enterprise-aware en el backend CE

**88 llamadas** a `prepend_mod_with` / `include_mod_with` / `extend_mod_with` en `app/`. Todos están **protegidos** por el initializer `01_inject_enterprise_edition_module.rb` que los hace **no-op** cuando `ChatwootApp.enterprise? == false`. 

**No es necesario tocar `app/`** para un fork CE puro. Los hooks extienden clases sólo si existe `enterprise/`.

### 7.3. Stub OSS-side del Enterprise API en el frontend

`app/javascript/dashboard/api/enterprise/account.js` exporta un cliente `EnterpriseAccountAPI` que llama a `/enterprise/api/v1/{checkout,subscription,limits,toggle_deletion,topup_checkout}`. El `ApiClient` (en `app/javascript/dashboard/api/ApiClient.js` líneas 30–32) agrega prefijo `/enterprise` cuando `enterprise: true`.

**Uso:** `accounts.js`, `PurchaseCreditsModal.v贡`, `AccountDelete.v贡` llaman a este cliente. Como `DISABLE_ENTERPRISE=true` por defecto en el fork, **estos endpoints 404 silenciosamente**. Decisión: o (a) el operador elimina `app/javascript/dashboard/api/enterprise/` en una fase futura, o (b) deja el stub con manejo de error. **No es bloqueador.**

### 7.4. Uso de `ChatwootApp.enterprise?` y `isEnterprise` en vistas y componentes

| Archivo | Línea | Decisión |
| --- | --- | --- |
| `app/view/api/v1/accounts/csat_survey_responses/downloadload.csv.erb` | 12, 30 | gardas con `if ChatwootApp.enterprise?` — **seguras, no tocar** |
| `app/view/super_admin/settings/show.html.erb` | 42, 104 | sólo cambia UI cuando enterprise está activo |
| `app/javascript/dashboard/router/dashboard/upgrade/UpgradePage.v贡` | 26, 89, 106 | sólo render si `isOnChatwootCloud` o `isEnterprise` |
| `app/javascript/dashboard/router/dashboard/captain/**` | varios | `v-if="isEnterprise"` — gardado |

**No son bloqueadores para un fork CE puro.** Las gardas evitan que la funcionalidad Enterprise se renderice.

---

## 8. ¿Qué partes se pueden modificar con bajo riesgo?

1. **`config/installation_config.yml`** — sólo valores por defecto (string). Cambio de `'Chatwoot'` → `'VentasFlow Inbox'`, `'https://www.chatwoot.com'` → `https://ventasflow.app`. Riesgo: bajo. No toca lgica.
2. **`public/brand-assets/logo*.svg`** —替换 de SVGs. Riesgo: nulo (assets estáticos).
3. **Vistas de super_admin e installation** (`app/view/installation/onboarding/index.html.erb`, `app/view/super_admin/devise/sessions/new.html.erb`, `app/view/super_admin/application/_navigation.html.erb`) — sólo texto y `alt=""`. Riesgo: bajo.
4. **`app/view/layouts/vieapp.html.erb`** — meta-description dinámica usa `@global_config['INSTALLATION_NAME']` — no requiere cambio si se cambia el config.
5. **Plantillas mailer base (`app/view/layouts/mailer/base.liquid`)** — fallback `brand_name`. Bajo riesgo.
6. **`app/view/devise/mailer/confirmation_instructions.html.erb`** — fallback `'Chatwoot'`. Bajo riesgo.
7. **`app.json`** (Heroku manifest) — sólo metadata, no afecta runtime.
8. **`app/javascript/shared/composables/useBranding.js`** — cambiar `'Chatwoot'` → `'VentasFlow Inbox'` como literal a buscar. Riesgo: bajo.
9. **`app/javascript/shared/store/globalConfig.js`** — cambiar el literal `'Chatwoot'` en `isAChatwootInstance` para detectar nuestra propia instancia. Bajo riesgo.

---

## 9. ¿Qué partes NO conviene cotar todavía?

1. **`app/model/conversation.rb`, `app/model/contact.rb`, `app/model/inbox.rb`** — lgica de negocio central. Riesgo: muy alto. Costo de modificar romper conversationses, asignación, automatización.
2. **`app/controller/api/v1/conversations_controller.rb` y familia** — lgica de API. Muy alto.
3. **`app/services/conversations/permission_filter_service.rb`** — lgica de permisos. Muy alto.
4. **`config/application.rb` líneas 43–53** — no retires la carga de `enterprise/`. El flag `DISABLE_ENTERPRISE` ya lo desactiva. La lgica de carga debe quedar.
5. **`app/javascript/dashboard/composables/useConfig.js`** — `isEnterprise` / `isOnChatwootCloud` se usan en muchos lados. No retires.
6. **`config/route.rb`** — el namespace `:enterprise` está gardado por `if ChatwootApp.enterprise?`; no tocar.
7. **`config/initializers/01_inject_enterprise_edition_module.rb`** — es el initializer que permite los hooks. No retitre.
8. **`db/schema.rb`, `db/migrate/`** — no agregar migraciones que cambien el schema上游 de la conversación.
9. **`app/javascript/widget/`** — widget público se inyecta en sitios de clientes. Cuidado con cambiar su branding.
10. **Action Cable channels** (`app/channels/`) — afectan la conversación en tiempo real.

---

## 10. Riesgos técnicos de mantener un fork

| # | Riesgo | Severidad | Mitigación |
| --- | --- | --- | --- |
| 1 | **Drift de upstream** (release 4.15.0 → main). Los fixes de seguridad y bugfixes que salgan en upstream requieren merge manual. | Alta | Mantener rama de sincronización de upstream (`develop` o `master`). Rebasear selectivamente. No usar `git rebase` destructivo. |
| 2 | **Cambios de esquema incompatibles**. Si upstream cambia `Conversation`, `Message`, etc., un merge puede romper la sesión. | Alta | Hacer migraciones aditivas propias. Nunca editar migraciones de upstream. Probar contra `develop` antes de PR. |
| 3 | **Gemfile / npm drift**. Subir gemas puede romper compatibilidad con Rails 7.1 o Vue 3.5. | Media |Pin de versiones en `Gemfile` y `package.json`. `bundle update --conservative`. |
| 4 | **88 hooks `prepend_mod_with`**. Si upstream agrega un hook y el initializer de Enterprise cambia, hay conflicto sutil. | Baja | No tocar los hooks. Conferse con initializer de upstream. |
| 5 | **Vue 3 → Vue 4 (futuro)**. Un cambio de major puede romper API pública. | Media | Pin Vue ^3.5.12. |
| 6 | **i18n**. 40+ archivos `config/locale/*.yml` con branding en valores. | baja | Cambio con find/replace; mantener `en.yml` canonical. |
| 7 | **Frontend build** — Vite ESM con dependencias inlineadas. | baja | Mantener `vite.config.ts` y `vite.lib.config.ts`. |
| 8 | **Empresa de assets (logo, favcon, illustsiones)**. | bajo | Reemplazar SVGs conservando rutas. |
| 9 | **Emails transaccional**. Lígeros en mailer hered to `BRAND_NAME`. | bajo | `BRAND_NAME` en `installation_config.yml`. |
| 10 | **Tests de Ruby con datos fixtures**. Si modificamos Conversation, los specs pueden fallar. | media |No modificar `spec/factories/conversation.rb` etc. hasta no贡a. |
| 11 | **Dependencias `@chatwoot/*` en `package.json`** (utils, prosemirror-schema, ninja-keys). | baja |Las podamos vendor o forkear. |
| 12 | **Telemetría a `hub.2.chatwoot.com`** (`lib/chatwoot_hub.rb`). | media |郊 de la emisión a hub está desacoplada; no se envia. `DISABLE_ENTERPRISE` la aísla. |

---

## 11. Riesgos legales / de marca

| # | Riesgo | Severidad | Mitigación |
| --- | --- | --- | --- |
| 1 | **Usar `Chatwoot` como nombre del producto.** | Alta |Reemplazar por `VentasFlow Inbox` en todo artefacto de marca. Mantener atribucción MIT y descargo de responsabilidad. |
| 2 | **Usar el logo de Chatwoot** (svg o raster) en el producto derivado. | Alta |Reemplazar por logo propio. No usar `public/brand-assets/logo*.svg` de Chatwoot. |
| 3 | **Usar el nombre "Chatwoot" en dominio, email, redeses sociales**. | Alta |Reemplazar por dominio propio (`@ventasflow.app`). |
| 4 | **Reclamar venta de Chatwoot en el flujo de conversación / onboarding. | media | El `installation_name` se inyecta en el chat con el cliente. No usar "Chatwoot" en respuestas. |
| 5 | **Inclima de "oficial" o "respaldado por Chatwoot"** sin autorización. | alta |El README del fork debe decir "basado en Chatwoot Community Edition" con atribucción MIT, no "oficial". |
| 6 | **Vender funcionalidad Enterprise** (SLA, SAML, Audit, Captain a escala) sin licencia. | alta |Excluir `enterprise/` del build y documentar. |
| 7 | **Reclamar el repo de `chatwoot/chatwoot` como propio**. | media |El fork debe estar en otro repo (`ventaasoft/ventasflow-inbox`). |
| 8 | **Reclamar tradu de `https://www.chatwoot.com`**. | alta |Reemplazar por `https://ventasflow.app` y `https://docs.ventasflow.app`. |
| 9 | **Carga de la "oficial" en la doc / web**. | media |README debe disociar y repos贡as. |
| 10 | **Reclamar "Chatwoot Mobile" o "Chatwoot SDK" como propios**. | alta |Bautizar "VentasFlow Inbox SDK" o similar. |

---

## 12. Recomendación: ¿fork puro, capa encima, o implementación self-hosted?

**Recomendación: fork CE puro + capa propia de marca + capa propia de nicho (cotizaciones).**

Justificación:

1. **El stack de Chatwoot CE** es Rails 7.1 + Vue 3 + Vite, con PostgreSQL, Redis y Sidekiq. Es un stack maduro y probado en producción. Reescribirlo desde cero es un proyecto de 12–18 meses. **No vale la pena para un nicho de PYME en LATAM.**

2. **La base MIT de Chatwoot ce** es la mejor опcódigo abierto para inboxes multicanal con WhatsApp, web y email. Reemplarla sería un error de negocio.

3. **No tiene sentido el "self implementación desde cero"** porque perdésemos toda la lgica de canales, asignación, conversación, etc. El 80% del trabajo ya está hecho.

4. **El modelo comercial cisión** es:
   - Tomar el CE (rama propia, 6–8 meses de mantenimiento upstream).
   - Excluir `enterprise/` del build de producción (con `DISABLE_ENTERPRISE`).
   - Rebranding seguro del nombre, logo, metadata, login, footer, emails.
   - Capa propia de nicho: módulo de cotizaciones, tareas, dashboard de venta.
   - Self-hosted para clientes (Docker compose, guías, backups).

5. **Lo que NO debe hacerse**:
   - "Otra Chatwoot Cloud": ya existe upstream y es una trampa de marca.
   - "Capa encima como Saa": es un servicio, no un producto.

**Decisión final:** **fork CE puro + capa propia de nicho (cotizaciones, tareas, ventas).** El producto se llama `VentasFlow Inbox` y se ofrece como **instalación self-hostada con soporte profesional para PYMEs en LATAM**.

---

## 13. Próimos pasos del auditoría

1. Crear rama `feature/ventasflow-rebrandce` (listo).
2. **Fase A — Limpieza legal y de marca**: docs `LEGAL_NOTES.md`, `OPEN_SOURCE_ATTRIBUTION.md`, `SELF_HOSTED_PLAN.md`. Configurar `DISABLE_ENTERPRISE=true` en `.env.example`. **No se toca `enterprise/`** — sólo se excluirá del build.
3. **Fase B — Rebranding seguro**: `installation_config.yml`, vistas de login, navegación del super admin, frontend store/composables, emails de bienvenida, README. Assets de marca (logo SVGs). `PRODD_DIRECTION.md` con la lista exhaustiva.
4. **Fase C — Módulo de cotizaciones**: spec en `QUott_module_spec.md`. Sin implementación hasta noaprobar la base.
5. **Fase D — Self-hosted**: docker-compose, .env.example, guía de install.
6. **Fase E — Validación**: lint, typecheck, tests, build. Reportar fallos.

**No se hace:**
- No se borra `enterprise/`.
- No se mergea `develop` de upstream con `--force` ni `--squash`.
- No se reescribe ninguna lgica de conversación.
- No se agrega dependencia externa.
- No se envia telemetría.
