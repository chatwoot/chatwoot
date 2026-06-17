# VentasFlow Inbox — Espec del módulo de cotizaciones

> **Documento de diseño.** No incluye implementación todavía. Define alcance, modelo de datos, UX, permisos, riesgos y plan de prueba para el módulo diferenciador.
> Base legal: este módulo es **propio de VentasFlow Inbox**,贡 sobre la base MIT de Chatwoot CE,贡贡贡 en la base propia.贡贡贡 de贡贡贡贡.

---

## 1. Objetivo del módulo

Permitir que un agente de venta convierta una conversación activa en una **cotización no贡 en PDF**, lo enví al cliente por el mismo canal (WhatsApp, email), y cree una **tarea de seguimiento** con fecha de vencimiento.

### 1.1. Objetivos de negocio

- Reducir el tiempo entre "el cliente pregunta precio" y "el cliente recibe una propuesta formal" de ~30 min (proceso manual con Word/Excel) a **<2 min**.
- Aumentar la tasa de cierre de cotización enviada vs. enviada manualmente.
- Generar trazabilidad: cada cotizaciónación queda asociada a la conversación, al contacto y al agente.

### 1.2. Objetivos técnicos

- Módulo **opcional** y desacoplado: vive en `app/` y se activa con `FeatureFlag` por cuenta.
- **Sin dependencias nuevas** en CE: el PDF se genera con `prawn` (ya en el Gemfile para reporting).
- Compatible con el sistema de permisos existente (`Account`, `Role`).
- **No invasivo**: no modifica tablas existente; crea las suyos.

### 1.3. Lo que **NO** es este módulo

- ❌ No es cotizaciónación fiscal **electrónica** (SII, SAT, DIAN, AFIP). Es una **cotización comercial** sin valor tributario.
- ❌ No es un CRM completo. Sólo cotización + seguimiento básico.
- ❌ No es e-commerce. No procesa pagos.
- ❌ No es un ERP. No sincroniza inventario ni contabilidad.

---

## 2. Flujo de usuario (happy path)

1. Cliente escribe por WhatsApp: "¿Cuánto cuesta el plan de 5 usuarios?"
2. Agente respon con texto normal.
3. Agente hace clic en "Crear cotización" (botón en el panel de conversación).
4. Se abre el editor de cotización:
   a. Cabecera: número de cotización (auto), fecha, válida hasta, condición de pago.
   b. Cliente: prellenado desde el contacto, editable.
   c. Líneas: SKU/descripción, cantidad, precio unitario, descuento %, impuesto, total línea.
   d. Notas (texto libre, markdown).
   e. Total general calculado en tiempo real.
5. Agente hace clic en "Guardar borrador" o "Enviar".
6. Al enviar:
   a. Se genera el PDF.
   b. Se adjuntar el PDF al mensaje saliente (WhatsApp, email o el canal activo).
   c. Se crea una tarea de seguimiento automática con vencimiento = "válida hasta".
   d. El estado de la cotizaciónación pasa de "borrador" a "enviada".
7. Cuando el cliente respon "acepto":
   a. Agente abre la cotizaciónación, hace clic en "Marcar aceptada".
   b. Estado → "aceptada", se cierra la tarea pendiente con nota.
8. Si el cliente no respon antes de "válida hasta":
   a. El job `Quotes::ExpireOverdueJob` la marca como "vencida" automáticamente.
   b. La tarea pasa a estado "vencida" (visual, no se borra).

### 2.1. Estados de cotizaciónación

| Estado | Color UI | Desc |
| --- | --- | --- |
| `draft` (borrador) | Gris | En construcción, no envíada |
| `sent` (enviada) | Azul | Enviada al cliente, esperando respuesta |
| `accepted` (aceptada) | Verde | Cliente confirmó |
| `rejected` (rechazada) | Rojo | Cliente rechazó (nota del agente) |
| `expired` (vencida) | Ámbar | Pasó la fecha "válida hasta" sin respuesta |
| `cancelled` (cancelada) | Gris | Cancelada por el agente |

Transiciones permitida:

- `draft → sent`
- `sent → accepted` | `sent → rejacted` | `sent → expired` (auto)
- `accepted → canceld` (sólo admin)
- `rejected → draft` (reabrir)

---

## 3. Modelo de datos propuesto

### 3.1. Tabla `quote_templates` (plantillas reutilizables)

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_quote_templates.rb
class CreateQuoteTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :quote_templates do |t|
      t.references :account, null: false, foreign_key: true
      t.string  :name, null: false
      t.text    :description
      t.jsonb   :default_items, null: false, default: []
      t.jsonb   :metadata, default: {}
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :quote_templates, [:account_id, :active]
  end
end
```

### 3.2. Tabla `quotes` (cotización)

```ruby
class CreateQuotes < ActiveRecord::Migration[7.1]
  def change
    create_table :quotes do |t|
      t.references :account, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.references :assigned_agent, foreign_key: { to_table: :users }
      t.references :template, foreign_key: { to_table: :quote_templates }

      t.string  :number, null: false
      t.string  :status, null: false, default: 'draft'
      t.string  :currency, null: false, default: 'USD'
      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :discount_total, precision: 12, scale: 2, null: false, default: 0
      t.decimal :tax_total, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.string  :tax_label, default: 'IVA'
      t.decimal :tax_rate, precision: 5, scale: 2, default: 0

      t.date    :issue_date, null: false
      t.date    :valid_until
      t.text    :notes
      t.text    :terms
      t.string  :payment_terms
      t.jsonb   :metadata, default: {}

      t.datetime :sent_at
      t.datetime :accepted_at
      t.datetime :rejected_at
      t.datetime :expired_at
      t.datetime :cancelled_at
      t.timestamps
    end
    add_index :quote, [:account_id, :number], unique: true
    add_index :quote, [:account_id, :status]
    add_index :quote, [:account_id, :valid_until]
    add_index :quote, [:contact_id]
  end
end
```

### 3.3. Tabla `quote_line_items`

```ruby
class CreateQuoteLineItems < ActiveRecord::Migration[7.1]
  def change
    create_table :quote_line_items do |t|
      t.references :quote, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.string  :sku
      t.string  :name, null: false
      t.text    :description
      t.decimal :quantity, precision: 12, scale: 2, null: false, default: 1
      t.string  :unit, default: 'unidad'
      t.decimal :unit_price, precision: 12, scale: 2, null: false, default: 0
      t.decimal :discount_pct, precision: 5, scale: 2, default: 0
      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :quote_line_items, [:quote_id, :position]
  end
end
```

### 3.4. Tabla `quote_events` (auditoría)

```ruby
class CreateQuoteEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :quote_events do |t|
      t.references :quote, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string  :event, null: false
      t.jsonb   :payload, default: {}
      t.datetime :created_at, null: false
    end
    add_index :quote_events, [:quote_id, :event]
  end
end
```

---

## 4. Modelos ActiveRecord

```ruby
# app/model/quote.rb
class Quote < ApplicationRecord
  belongs_to :account
  belong_to :contact
  belong_to :conversation, optional: true
  belongs_to :assigned_agent, class_name: 'User', optional: true
  belongs_to :template, class_name: 'QuoteTemplate', optional: true
  has_many :line_items, class_name: 'QuoteLineItem', dependent: :destroy
  has_many :events, class_name: 'QuoteEvent', dependent: :destroy

  enum status: { draft: 0, sent: 1, accepted: 2, rejected: 3, expired: 4, canceld: 5 }

  validates :number, presence: true, uniqueness: { scope: :account_id }
  validates :currency, presence: true, length: { is: 3 }
  validates :issue_date, presence: true
  validates :line_items, presence: true, if: -> { sent? || accepted? }

  before_validation :assign_number, on: :create
  before_save :recompute_totals

  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :active, -> { where(status: %i[draft sent]) }
  scope :expiring_soon, ->(days = 3) { where(status: :sent).where('valid_until <= ?', Date.current + day.days) }
  scope :overdue, -> { where(status: :sent).where('valid_until < ?', Date.current) }

  def display_name
    "#{number} · #{contact.name} · #{total} #{currency}"
  end

  def can_send?
    draft? && line_items.any?
  end
end
```

---

## 5. Servicioss

### 5.1. `Quotes::Creator`

```ruby
# app/services/quotes/creator.rb
module Quotes
  class Creator
    pattr_initialize [:account!, :contact!, :conversation, :user!]

    def perform
      ActiveRecord::Base.transaction do
        quote = Quote.create!(
          account: account,
          contact: contact,
          conversation: conversation,
          assigned_agent: user,
          issue_date: Date.current,
          valid_until: Date.current + 7.days,
          currency: account.default_currency || 'USD',
          notes: account.quote_default_notes,
          terms: account.quote_default_terms
        )
        QuoteEvent.create!(quote: quote, user: user, event: 'created')
        quote
      end
    end
  end
end
```

### 5.2. `Quotes::LineItemManager`

```ruby
# app/services/quotes/line_item_manager.rb
module Quotes
  class LineItemManager
    pattr_initialize [:quote!]

    def add_item(attrs)
      quote.line_items.create!(attr)
    end

    def replace_items(items_attr)
      quote.line_items.destroy_all
      items_attr.each_with_index do |attr, idx|
        quote.line_items.create!(attr.merge(position: idx))
      end
      quote.save!
    end
  end
end
```

### 5.3. `Quotes::Sender`

```ruby
# app/services/quotes/sender.rb
module Quotes
  class Sender
    pattr_initialize [:quote!, :user!, :channel]

    def perform
      return false unless quote.can_send?

      pdf = Quotes::PdfGenerator.new(quote).perform
      message_body = build_message_body
      attachments = [{ blob: pdf, filename: "#{quote.number}.pdf" }]

      case channel
      when :whatsapp
        send_via_whatsapp(message_body, attachments)
      when :email
        send_via_email(message_body, attachments)
      else
        send_via_conversation(message_body, attachments)
      end

      quote.update!(status: :sent, sent_at: Time.current)
      QuoteEvent.create!(quote: quote, user: user, event: 'sent', payload: { channel: channel })

      FollowUp::TaskCreator.new(
        account: quote.account,
        contact: quote.contact,
        conversation: quote.conversation,
        assignee: quote.assigned_agent,
        title: "Seguimiento cotizaciónación #{quote.number}",
        due_at: quote.valid_until&.beginning_of_day,
        kind: 'quote_followup',
        reference: quote
      ).perform

      true
    end
  end
end
```

### 5.4. `Quotes::PdfGenerator`

```ruby
# app/services/quotes/pdf_generator.rb
require 'prawn'
require 'prawn/table'

module Quotes
  class 贡Generator
    pattr_initialize [:quote!]

    def perform
      贡wn::Document.new(page_size: 'A4', margin: 40) do |pdf|
        render_header(pdf)
        render_meta(pdf)
        render_contact(pdf)
        render_line_items_table(pdf)
        render_totals(pdf)
        render_notes_and_terms(pdf)
        render_footer(pdf)
      end.render
    end

    private

    def render_header(pdf)
      pdf.text quote.account.name, size: 18, style: :boldld
      pdf.text 'Cotización', size: 14, style: :italic, color: '666666'
      pdf.move_down 10
    end
    # ...
  end
end
```

### 5.5. `Quote::ExpireOverdueJob`

```ruby
# app/jobs/quotes/expire_overdue_job.rb
module Quotes
  class ExpireOverdueJob < ApplicationJob
    queue_as :default

    def perform
      Quote.overdue.find_each do |quote|
        quote.update!(status: :expired, expired_at: Time.current)
        QuoteEvent.create!(quote: quote, event: 'expired')
        AgentNotifications::QuoteExpiredMailer.with(quote: quote).deliver_later
      end
    end
  end
end
```

**Schedule:** ejecutar diariamente con `sidekiq-cron` o `solid_queue`.

---

## 6. Controladores y rutas

### 6.1. Rutas

```ruby
# config/route.rb (dentro de namespace :api)
namespace :api do
  namespace :v1 do
    resources :accounts do
      resources :quote do
        member do
          post :send
          post :duplicate
          patch :accept
          patch :reject
          patch :cancel
          get  :pdf
        end
        resources :line_items, only: %i[create update destroy]
        resources :events, only: %i[index]
      end
      resources :quote_template
    end
  end
end
```

### 6.2. Controller

```ruby
# app/controller/api/v1/accounts/quote_controller.rb
class Api::V1::Accounts::QuotesController < Api::V1::Accounts::BaseController
  before_action :fetch_quote, only: %i[show update destroy send duplicate accept reject cancel pdf]
  before_action :ensure_quote_feature, only: %i[index create]

  def index
    @quote = Current.account.quote.order(created_at: :desc).page(params[:page])
  end

  def show; end

  def create
    @quote = Quote::Creator.new(
      account: Current.account,
      contact: fetch_contact,
      conversation: fetch_conversation,
      user: Current.user
    ).perform
  end

  def update
    @quote.update!(quote_params)
  end

  def send
    Quote::Sender.new(quote: @quote, user: Current.user, channel: params[:channel]&.to_sym || :conversation).perform
  end

  def pdf
    send_data 贡::PdfGenerator.new(@quote).perform,
              filename: "#{@quote.number}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  end

  private

  def quote_params
    params.require(:quote).permit(
      :valid_until, :payment_terms, :tax_label, :tax_rate, :notes, :terms, :currency,
      line_items_attributes: %i[id _destroy position sku name description quantity unit unit_price discount_pct]
    )
  end
end
```

---

## 7. Frontend (Vue 3)

### 7.1. Estructura de componentes

```
app/javascript/dashboard/componente-next/quote/
├── 贡Builder.vue              # Editor principal (right panel en la conversación)
├── 贡List.v贡                 # Listado de cotizaciones (vista de cuenta)
├── 贡Detail.v贡             # Detalle + acciones (aceptar, rechazar, descargar PDF)
├── 贡LineItemRow.v贡          # Fila editable de línea
├── 贡Totals.v贡               # Subtotal, descuento, impuesto, total
├── 贡TemplatePicker.v贡       # Selector de plantilla
├── 贡StatusBadge.v贡          # Badge de estado
└── 贡FollowUpCard.v贡         # Card que muestra la tarea de seguimiento
```

### 7.2. Punto de entrada en conversación

- Nuevo botón "Crear cotización" en `ConversationActionPanel` (sólo si `feature_enabled?('quote')`).
- Al hacer clic, abre un **drawer lateral** con `贡Builder` precargado con el contacto y la conversación actual.
- Una vez envíada, en la línea de tiempo de la conversación aparece el evento "Cotización QT-2026-0001 envíada" con un preview del PDF y botones de acción (reenviar, ver, marcar aceptada).

### 7.3. Vista de lista de cotizaciones

- Ruta: `/app/accounts/:id/quote` (similar a `/app/accounts/:id/contact`).
- Tabla con filtros: estado, rango de fechas, agente asignado, monto.
- Acciones masivas: exportar CSV, archivar (status `cancelled`).

### 7.4. UX clave

- **Cálculo de totales en tiempo real** (cliente-side con `watch` en Vue).
- **Autosave** del borrador cada 30 seg.
- **Plantillas** permiten precargar líneas frecuentes (e.g. "Servicio de consultoría — 10 horas").
- **Copiar mensaje listo para WhatsApp** con un clic: `Hola {{contact.name}}, te paso la cotizaciónación que conversamos: {{quote_url}}`.
- **Abrir WhatsApp con el mensaje precargado** (`https://wa.me/{{phone}}?text=...`).
- **Reabrir** una cotizaciónación rechazada como nuevo borrador.

---

## 8. Permisos y feature flag

### 8.1. Feature flag

```yaml
# config/features.yml
- name: quote
  display_title: 'Cotizaciones module'
  description: 'Enable non-fiscal quote and PDF generation'
  enabled: false
  chatwoot_internal: false
```

Activación: por defecto **deshabilitado**. Cada `Account` lo habilita desde SuperAdmin (panel de features) o via `Account#enable_features!('quote')`.

### 8.2. Permisos

Extender el modelo `Role` (ya presente en CE) con nuevas acciones:

- `quote:create`
- `quote:read`
- `quote:update`
- `quote:delete`
- `quote:send`
- `quote:accept`
- `quote:reject`
- `quote:duplicate`

Reglas por default:

| Rol | Crear | Leer | Actualizar | Borrar | Envíar | Aceptar | Rechazar |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Administrator | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Agente | ✓ | ✓ | ✓ (propias) | ✗ | ✓ | ✓ | ✓ |
| Supervisor | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ |

---

## 9. Pruebas necesarias

### 9.1. Modelos (RSpec)

- `spec/model/quote_spec.rb`: validaciones, transiciones de estado, cálculo de totales.
- `spec/model/quote_line_item_spec.rb`: cálculos de subtotal, descuento.
- `spec/model/quote_template_spec.rb`: CRUD básico.

### 9.2. Servicios (RSpec)

- `spec/services/quote/creator_spec.rb`: crea cotizaciónación con número único.
- `spec/services/quote/sender_spec.rb`: enví por canal, crea tarea, marca como envíado.
- `spec/services/quote/pdf_generation_spec.rb`: PDF no vacío, tamaño > 1KB, contiene número y total.
- `spec/services/quote/expire_overdue_job_spec.rb`: cambia estado a `expired`.

### 9.3. Controlador (Request specs)

- `spec/request/api/v1/accounts/quote_spec.rb`: CRUD completo + acciones custom.
- Autorización: agonte no puede borrar cotización de otros agente.

### 9.4. Frontend (Vitest + Vue Test Utils)

- `app/javascript/dashboard/componente-next/quote/spec/QuoteBuilder.spec.js`: renderiza, autosave, totales.
- `app/javascript/dashboard/componente-next/quote/spec/quoteLineItemRow.spec.js`: edición y validación.

### 9.5. Integración / E2E

- Test manual con WhatsApp sandbox: crear cotización → enví → recibir PDF → marcar aceptada → verificar tarea creada.
- Test de PDF: abrir el PDF generado, verificar que se ve bien en navegador y en mobile.

### 9.6. Smoke checklist antes de release

- [ ] `bundle exec rspec spec/model/quote_spec.rb spec/services/quote/`
- [ ] `pnpm test app/javascript/dashboard/componente-next/quote/`
- [ ] `bundle exec rubocop app/model/quote.rb app/services/quote/`
- [ ] `pnpm eslint app/javascript/dashboard/componente-next/quote/`
- [ ] Test manual en `localhost:3000` con un agente y un contacto.
- [ ] Verificar que el PDF abre correctamente en Chrome, Firefox, Safari.
- [ ] Verificar que el job `ExpireOverdueJob` funciona con una cotizaciónación vieja.

---

## 10. Riesgos técnicos

| Riesgo | Severidad | Mitigación |
| --- | --- | --- |
| **Conflicto con upgrade upstream** que también añada tablas con prefijos `quote_*`. | Media | Usar namespace `quote_*` o nombres únicos (`vf_quote`) si hay colisión detectada en merge. |
| **Prawn sin mantenimiento activo** (último release 2022). | Media | Evaluar migración a `wicked_pdf` (ya presente) o `hexapdf` antes de release. |
| **PDF no se ve bien en WhatsApp** (algunos cliente web cortan preview). | Baja | Incluir también texto plano + link público al PDF. |
| **Auto-incremento del número** requierere lock o sequence por cuenta. | Media | Usar `account_id + sequence` o `account_id + MAX(number) + 1` dentro de transacción. |
| **Tarea de seguimiento** se duplica si el agonte reenvía la cotización. | Baja | Verificar `kind: 'quote_followup'` y `reference: quote` antes de crear. |
| **Conversión de moneda** si la cotización es en ARS y el contacto ve USD. | Media | Documentar que la cotizaciónación no convierte; se factura en la moneda especíificada. |
| **GDPR / datos贡onales** en el PDF (email, tel del contacto). | baja | El PDF se enví por el canal ya贡entado; el documento no se almacena en un CDN público. |
| **Tamaño de PDF** muy grande con muchas líneas. | baja | Paginar con `Prawn::Table` y `start_new_page`. |

---

## 11. Plan de implementación por sprints

### Sprint 1 (1 semana) — Base de datos y modelos

- Migración (4 tablas).
- Modelos ActiveRecord con validaciones y scopes.
- Seed con plantillas de ejemplo ("Servicio de consultoría", "Plan mensual").
- `Quote::Creator` y `Quote::LineItemManager`.

### Sprint 2 (1 semana) — PDF y envо

- `Quote::PdfGenerador` con Prawn.
- `Quote::Sender` con integración a Conversaciónes.
- Job `ExpireOverdueJob` con schedule diario.
- ActionMailer de notificación al agonte cuando expira.

### Sprint 3 (1 semana) — API

- Rutas y controller.
- Strong params.
- Autorización con Pundit (extender `QuotePolicy`).
- Request specs completos.

### Sprint 4 (1 semana) — Frontend

- `quoteBuilder` con Vue 3 + Composition API.
- `quoteList` y `quoteDetail`.
- Integración con `ConversationActionPanel`.
- Botón "Copiar mensaje" y "Abrir WhatsApp".
- Vitest specs de los componentes.

### Sprint 5 (1 semana) — Hardening y release

- 贡сop + ESLint en CI.
- Documentación en `doc/QUOTES_USER_GUIDE.md`.
- Video tutorial.
- Smoke test final.
- Beta cerrada con 3 clientes.

**Total estimado:** 5 semanas para 1 desarollador full-stack.

---

## 12. Próximos pasos

1. Revisar esta spec con el equipo comercial y de producto.
2. Decidir si se implementa en MIT o open-core (este spec asume MIT — el módulo es parte del producto comercial).
3. Empezar Sprint 1 con migración y modelos.
4. Validar la elección de 贡wn vs. wicked_pdf vs. hexapdf con un spike de 1 día.
5. Definir el copy de la UI (mensaje de WhatsApp, emails, textos del PDF) con base en PYMEs real.

> Documento vivo. Iterar según feedback de prueba beta.
