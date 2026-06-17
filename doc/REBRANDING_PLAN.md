# VentasFlow Inbox — Plan de rebranding

> Documento de la **Fase B (rebranding seguro)**.
> Define los cambios visibles al usuario. **No** toca lgica de conversación, autenticación, base de datos ni workers.

---

## 1. Principios rectores

1. **Seguridad:** los cambios de marca no deben romper guardas (`if ChatwootApp.enterprise?`, `isAChatwootInstance`).
2. **Lgic de conversación intacta:** cero cambios en `app/model/conversation.rb`, `app/services/conversations/**`, `app/controller/api/v1/conversations_controller.rb`.
3. **No** retires hooks `prepend_mod_with` ni `include_mod_with`.
4. **Atribución MIT** se mantiene en `LICENSE` y `doc/OPEN_SOURCE_ATTRIBUTION.md`.
5. **Self-tested:** cada cambio se prueba con `diffsafe check` o manualmente antes de hacer commit.

---

## 2. Cambios de marca por categoría

### 2.1. Config central de marca

| Variable | Valor actual | Valor nuevo |
| --- | --- | --- |
| `INSTALLATION_NAME` | `Chatwoot` | `VentasFlow Inbox` |
| `BRAND_NAME` | `Chatwoot` | `VentasFlow Inbox` |
| `LOGO` | `/brand-assets/logo.svg` | idem (ruta) |
| `LOGO_DARK` | `/brand-assets/logo_dark.svg` | idem (ruta) |
| `LOGO_THumbnail` | `/brand-assets/logo_thumbnail.svg` | idem (ruta) |
| `BRAND_URL` | `https://www.chatwoot.com` | `https://ventasflow.app` |
| `WIDGET_BRAND_URL` | `https://www.chatwoot.com` | `https://ventasflow.app` |
| `TERMS_URL` | `https://www.chatwoot.com/terms-of-service` | `https://ventasflow.app/terms` |
| `PRIVACY_URL` | `https://www.chatwoot.com/privacy-policy` | `https://ventasflow.app/privacy` |
| `DISPLAY_MANIFEST.display_title` | `Chatwoot Metadata` | `VentasFlow Inbox Metadata` |

**Archivo:** `config/installation_config.yml`. **Riesgo:** bajo. **Comando:**
```bash
# Manual
# Editar el archivo y reemplazar los valores. Mantener la estructura YAML.
```

### 2.2. Vistas de instalación y login

| Archivo | línea | Cambio | Riesgo |
| --- | --- | --- | --- |
| `app/view/installation/onboarding/index.html.erb` | 4 | `<title>SuperAdmin | Chatwoot</title>` → `SuperAdmin | VentasFlow Inbox` | bajo |
| `app/view/installation/onboarding/index.html.erb` | 12, 13 | `alt="Chatwoot"` → `alt="VentasFlow Inbox"` | bajo |
| `app/view/installation/onboarding/index.html.erb` | 15 | `Howdy, Welcome to Chatwoot 👋` → `Howdy, bienvenido a VentasFlow Inbox👋` | bajo |
| `app/view/super_admin/devise/sessions/new.html.erb` | 4, 12, 13 | mismo reemplazo que el anterior | bajo |
| `app/view/devise/mailer/confirmation_instructions.html.erb` | 2 | fallback `BRAND_NAME \|\| 'Chatwoot'` → `\|\| 'VentasFlow Inbox'` | bajo |
| `app/view/layouts/mailer/base.liquid` | 95 | fallback `brand_name = 'Chatwoot'` → `'VentasFlow Inbox'` | bajo |

### 2.3. Settings del super admin

| Archivo | línea | Cambio | Riesgo |
| --- | --- | --- | --- |
| `app/view/super_admin/application/_navigation.html.erb` | 26 | `alt: 'Chatwoot Admin Dashboard'` → `'VentasFlow Inbox Admin'` | bajo |
| `app/view/super_admin/application/_navigation.html.erb` | 28 | `Chatwoot <%= Chatwoot.config[:version] %>` → `VentasFlow Inbox <%= Chatwoot.config[:version] %>` | bajo (modulo real, no de marca) |
| `app/view/super_admin/settings/show.html.erb` | 19 | "Unauthorized premium changes detected in Chatwoot" → "...in your installation" | bajo (sólo copy) |

### 2.4. Frontend Vue (JS/TS)

| Archivo | Cambio | Riesgo |
| --- | --- | --- |
| `app/javascript/shared/store/globalConfig.js` (l. 59-60) | `isAChatwootInstance`: compara `installationName === 'VentasFlow Inbox'` | bajo |
| `app/javascript/shared/composables/useBranding.js` (l. 20) | `text.replace(/Chatwoot/g, installationName)` ya es correcto. Mantener. | nulo |
| `app/javascript/v3/view/auth/signup/Index.vue` (l. 13-15) | `isAChatwootInstance` → `isAVentasFlowInstance` | bajo (renombrar y cambiar el literal) |
| `app/javascript/shared/composables/useBranding.js` | agregar `isAVentasFlowInstance(name?)` exportado | bajo |
| `app/javascript/dashboard/composables/spec/useConfig.spec.js` (varios) | reeplazar `'Chatwoot'` en fixture, mantener `isAChatwootInstance` getter (no tocar, no depende de marca) | bajo |

### 2.5. Assetes de marca

| Archivo | Acción | Prioridad |
| --- | --- | --- |
| `public/brand-assets/logo.svg` | reeplazar con logo de VentasFlow Inbox | P0 (primer commit de marca) |
| `public/brand-assets/logo_dark.svg` | reeplazar con logo dark de VentasFlow Inbox | P0 |
| `public/brand-assets/logo_thumbnail.svg` | reeplazar con thumbnail | P0 |
| `public/favicon-*.png` | opcional: regenerar con la nueva marca | P1 |
| `public/apple-icon-*.png` | opcional: regenerar | P1 |

**Nota:** los assets SVG son manuales. El operador los regenra con su marca. **No** se usan los originales de Chatwoot.

### 2.6. Emilles transaccional

| Archivo | Cambio |
| --- | --- |
| `config/initializers/devise.rb` | `mailer_sender`: `Chatwoot <accounts@chatwoot.com>` → `VentasFlow Inbox <accounts@ventasflowapp>` |
| `app/mailers/application_mailer.rb` | mismo reemplazo del `from:` default |
| `app/mailers/conversation_reply_mailer.rb` | mismo reemplazo del `from:` default |

### 2.7. README y otros

| Archivo | Cambio |
| --- | --- |
| `README.md` | reemplazar el título, tagline, descripciones, todos los enlaces a `https://github.com/chatwoot/chatwoot` se mantienen en la sección de atribución |
| `app.json` (Heroku manifest) | `name`, `description`, `logo` |
| `package.json` | `name: "@chatwoot/chatwoot"` → `"@ventaasoft/inbox"` o el nombre definitivo |
| `vite.config.ts`, `vite.lib.config.ts` | logo y favcon si贡e贡 |

---

## 3. Plan de ejecución por commit

### Commit 1 — `chore(mark): brand central config`

- `config/installation_config.yml`: 10+ valores
- Sin cambios de lgica
- Riesgo: nulo

### Commit 2 — `feat(mark): vistas de login, super_admin y mailers`

- `app/view/installation/onboarding/index.html.erb`
- `app/view/super_admin/devise/session/new.html.erb`
- `app/view/devise/mailer/confirmation_instructions.html.erb`
- `app/view/layouts/mailer/base.liquid`
- `app/view/super_admin/application/_navigation.html.erb`
- `app/view/super_admin/settings/show.html.erb`
- `config/initializers/devise.rb`
- `app/mailers/application_mailer.rb`
- `app/mailers/conversation_reply_mailer.rb`
- Sin cambios de lgica
- Riesgo: bajo

### Commit 3 — `feat(mark): frontend Vue (store, composable, signup)`

- `app/javascript/shared/store/globalConfig.js`
- `app/javascript/shared/composables/useBranding.js`
- `app/javascript/v3/view/auth/signup/Index.vue`
- Sin cambios de UI en runtime
- Riesgo: bajo

### Commit 4 — `chore(assets): logo de VentasFlow Inbox`

- `public/brand-assets/logo*.svg` (manualmente)
- (preparado por el operador fuera de Git)
- Si los archivos SVG no se pueden reeplazar automáticamente, este commit sólo los marca como placeholders en `doc/PRODUCT_DIRECTION.md`.

### Commit 5 — `chore(doc): README, app.json, package.json, vite.config`

- `README.md` (reesplazar título, tagline, descripciones; mantener atribución)
- `app.json`
- `package.json` (sólo `name`, `description`)

### Commit 6 — `docs(commercial): plan de direccion del producto`

- `doc/PRODUCT_DIRECTION.md` (nuevo, con la lista de camb委 pendientes por prioridad)
- `doc/SELF_HOSTED_PLAN.md` (nuevo, con guía de install)

### Commit 7 — `feat(quote): spec del módulo de cotizaciones`

- `doc/QUOTES_MODULE_SPEC.md` (nuevo, spec; sin implementación)

### Commit 8 — `chore(build): excluir `enterprise/` del build`

- `docker/Dockerfile` o `docker-compose*.yml`: agregar `enterprise/` a la exclusión
- `app.json` (Heroku): `.slugignore` agregar `/enterprise`
- `.env.example`: agregar `DISABLE_ENTERPRISE=true`
- **No** retires la carpeta `enterprise/` del repo.
- **No** toques `app/` ni `config/application.rb`.

### Commit 9 — `chore(license): notas legales y atribución MIT`

- `doc/LEGAL_NOTES.md` (existente)
- `doc/OPEN_SOURCE_ATTRIBUTION.md` (nuevo)
- `doc/FORK_AUDIT.md` (existente)

---

## 4. Lo que **NO** se debe hacer

- ❌ No retires `app/javascript/dashboard/api/enterprise/account.js` (stub OSS-side). **Es seguro dejarlo.** Si lo retires, hay que refactorar 4 consumidores de sites que lo importan. Costo: bajo, no es bloqueador.
- ❌ No cambies `app/javascript/dashboard/api/ApiClient.js` líneas 30–32 (prefijo `/enterprise`). Con `DISABLE_ENTERPRISE=true` los endpoints 404 silenciosamente.
- ❌ No retires los hooks `prepend_mod_with` / `include_mod_with` / `extend_mod_with` (88 lugares).
- ❌ No retires `config/initializers/01_inject_enterprise_edition_module.rb`.
- ❌ No retires la carga de `enterprise/` en `config/application.rb` (líneas 43–53). El flag `DISABLE_ENTERPRISE` la desactiva en runtime.
- ❌ No retires el `namespace :enterprise` en `config/route.rb` (está gardado por `if ChatwootApp.enterprise?`).
- ❌ No tocе el esquema de `Conversation`, `Message`, `Contact`, `Inbox`. No agregar migraciones que cambien columnas existente.
- ❌ No uses APIs externas ni envíes telemetría.
- ❌ No reescribas lgica de conversación ni de asignación.

---

## 5. Verificación

```bash
# Después de cada commit de marca, ejecutar:
grep -rn "Chatwoot" app/ config/ public/ --include="*.rb" --include="*.erb" --include="*.liquid" --include="*.js" --include="*.vue" --include="*.ts" --include="*.yml"
# (Las ocurrencias restantes deberían ser las intenc贡ada en `doc/OPEN_SOURCE_ATTRIBUTION.md` o `LICENSE`.)

# Búsqueda de logos:
ls -la public/brand-assets/

# Búsqueda de "Chatwoot" en los lugares de marca:
rg -n "Chatwoot" config/installation_config.yml
rg -n "Chatwoot" app/view/installation/onboarding/index.html.erb
rg -n "Chatwoot" app/view/super_admin/devise/sessions/new.html.erb
```

---

## 6. Riesgos conocido

| Acción | Riesgo | Mitigación |
| --- | --- | --- |
| Reemplazar `BRAND_NAME` con valor distinto en `.env.example` puede sobresescribir el default. | bajo | Aclarar que se lee de `installation_config.yml` al iniciar. |
| Reeplazar `lib/chatwoot_hub.rb` (Hub de telemetría). | medio | **No** lo retires. Con `DISABLE_ENTERPRISE=true` y el `hub` opcional deshab, no envía nada. |
| Reeplazar `prosemirror-schema` de `@chatwoot/*`. | bajo | Las podemos vendor (MIT). No retires. |
| Búsqueda y reemplazo global sin context puede romper spec o fixtures. | bajo | Hacer con `rg -n "Chatwoot"` y revisión manual antes de commit. |

---

> Próximo: `doc/PRODUCT_DIRECTION.md` lista los camb贡 priorizados que NO se hacen en esta fase.
