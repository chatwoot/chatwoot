# FAQ API Documentation

Sistema de Preguntas Frecuentes (FAQs) con soporte multi-idioma para la Base de Conocimientos.

## Tabla de Contenidos

- [Arquitectura de Base de Datos](#arquitectura-de-base-de-datos)
  - [Diagrama de Relaciones](#diagrama-de-relaciones)
  - [Tabla: faq_categories](#tabla-faq_categories)
  - [Tabla: faq_items](#tabla-faq_items)
  - [Tabla: inbox_faq_categories](#tabla-inbox_faq_categories)
- [Endpoints para Administradores](#endpoints-para-administradores)
  - [FAQ Categories](#faq-categories)
  - [FAQ Items](#faq-items)
  - [Inbox FAQ Configuration](#inbox-faq-configuration)
- [Endpoint para Bot](#endpoint-para-bot)
  - [Bot FAQs](#bot-faqs)
- [Ejemplos de Uso](#ejemplos-de-uso)

---

## Arquitectura de Base de Datos

El sistema de FAQs utiliza 3 tablas principales que se conectan con las tablas existentes `accounts`, `users` e `inboxes`.

### Diagrama de Relaciones

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           DIAGRAMA ENTIDAD-RELACIÓN                             │
└─────────────────────────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │   accounts   │
    │──────────────│
    │ id           │◄─────────────────────────────────────────────┐
    │ name         │                                              │
    │ ...          │                                              │
    └──────────────┘                                              │
           │                                                      │
           │ 1:N                                                  │
           ▼                                                      │
    ┌──────────────────────┐         ┌──────────────────────┐    │
    │   faq_categories     │         │      faq_items       │    │
    │──────────────────────│         │──────────────────────│    │
    │ id                   │◄────────│ faq_category_id (FK) │    │
    │ account_id (FK)  ────┼─────────┼► account_id (FK) ────┼────┤
    │ parent_id (FK) ──────┼──┐      │ position             │    │
    │ name                 │  │      │ is_visible           │    │
    │ description          │  │      │ translations (JSONB) │    │
    │ position             │  │      │ created_by_id (FK)───┼────┼──┐
    │ is_visible           │  │      │ updated_by_id (FK)───┼────┼──┤
    │ created_by_id (FK)───┼──┼──┐   │ created_at           │    │  │
    │ updated_by_id (FK)───┼──┼──┤   │ updated_at           │    │  │
    │ created_at           │  │  │   └──────────────────────┘    │  │
    │ updated_at           │  │  │              ▲                │  │
    └──────────────────────┘  │  │              │ 1:N            │  │
           ▲    │             │  │              │                │  │
           │    │ Auto-       │  │   ┌──────────┴───────────┐    │  │
           │    │ referencia  │  │   │  Categoría contiene  │    │  │
           │    │ (árbol)     │  │   │  múltiples FAQs      │    │  │
           │    └─────────────┘  │   └──────────────────────┘    │  │
           │                     │                               │  │
           │ N:M                 │                               │  │
           │                     │                               │  │
    ┌──────┴───────────────┐     │                               │  │
    │ inbox_faq_categories │     │      ┌──────────────┐         │  │
    │──────────────────────│     │      │    users     │         │  │
    │ id                   │     │      │──────────────│         │  │
    │ inbox_id (FK) ───────┼──┐  └──────┼► id          │◄────────┼──┘
    │ faq_category_id (FK) │  │         │ name         │         │
    │ created_at           │  │         │ email        │         │
    │ updated_at           │  │         │ ...          │         │
    └──────────────────────┘  │         └──────────────┘         │
           ▲                  │                                  │
           │                  │                                  │
           │ N:M              │                                  │
           │                  ▼                                  │
           │         ┌──────────────┐                            │
           │         │   inboxes    │                            │
           │         │──────────────│                            │
           └─────────┤ id           │                            │
                     │ account_id ──┼────────────────────────────┘
                     │ name         │
                     │ channel_type │
                     │ ...          │
                     └──────────────┘
```

### Flujo de Datos

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              FLUJO DE CONSULTA DEL BOT                          │
└─────────────────────────────────────────────────────────────────────────────────┘

   INBOX (WhatsApp)              CATEGORÍAS                    FAQs
   ═══════════════              ══════════════              ═══════════

   ┌─────────────┐    busca     ┌─────────────┐   contiene  ┌─────────────┐
   │  Inbox #5   │─────────────►│ Categoría 1 │────────────►│   FAQ #1    │
   │  WhatsApp   │              │  "Envíos"   │             │   FAQ #2    │
   └─────────────┘              └─────────────┘             │   FAQ #3    │
         │                            │                     └─────────────┘
         │                            │ subcategoría
         │                            ▼
         │                      ┌─────────────┐             ┌─────────────┐
         │                      │ Categoría 2 │────────────►│   FAQ #4    │
         │                      │"Internac."  │             │   FAQ #5    │
         │                      └─────────────┘             └─────────────┘
         │
         │              busca   ┌─────────────┐             ┌─────────────┐
         └─────────────────────►│ Categoría 3 │────────────►│   FAQ #6    │
                                │  "Pagos"    │             │   FAQ #7    │
                                └─────────────┘             └─────────────┘

   El bot consulta UN endpoint → Recibe TODAS las FAQs visibles de sus categorías
```

---

### Tabla: faq_categories

**Propósito:** Almacena las categorías de FAQs con estructura jerárquica (árbol de 2 niveles).

```sql
CREATE TABLE faq_categories (
    id                BIGSERIAL PRIMARY KEY,
    account_id        BIGINT NOT NULL REFERENCES accounts(id),
    parent_id         BIGINT REFERENCES faq_categories(id),  -- Auto-referencia para subcategorías
    name              VARCHAR NOT NULL,
    description       TEXT,
    position          INTEGER NOT NULL DEFAULT 0,
    is_visible        BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_id     BIGINT REFERENCES users(id),
    updated_by_id     BIGINT REFERENCES users(id),
    created_at        TIMESTAMP NOT NULL,
    updated_at        TIMESTAMP NOT NULL
);

-- Índices para optimizar consultas
CREATE INDEX idx_faq_categories_account_id ON faq_categories(account_id);
CREATE INDEX idx_faq_categories_parent_id ON faq_categories(parent_id);
CREATE INDEX idx_faq_categories_account_parent ON faq_categories(account_id, parent_id);
CREATE INDEX idx_faq_categories_account_position ON faq_categories(account_id, position);
CREATE INDEX idx_faq_categories_is_visible ON faq_categories(is_visible);
```

**Descripción de Columnas:**

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| `id` | BIGSERIAL | NO | auto | Identificador único |
| `account_id` | BIGINT | NO | - | FK a `accounts`. Aísla datos por cuenta |
| `parent_id` | BIGINT | SÍ | NULL | FK auto-referencial. NULL = categoría raíz |
| `name` | VARCHAR | NO | - | Nombre de la categoría (ej: "Envíos") |
| `description` | TEXT | SÍ | NULL | Descripción opcional |
| `position` | INTEGER | NO | 0 | Orden de visualización (menor = primero) |
| `is_visible` | BOOLEAN | NO | TRUE | Si el bot puede ver esta categoría |
| `created_by_id` | BIGINT | SÍ | NULL | FK a `users`. Quién creó |
| `updated_by_id` | BIGINT | SÍ | NULL | FK a `users`. Última modificación |
| `created_at` | TIMESTAMP | NO | auto | Fecha de creación |
| `updated_at` | TIMESTAMP | NO | auto | Última actualización |

**Estructura de Árbol (Ejemplo):**

```
account_id=1:
├── Categoría "Envíos" (id=1, parent_id=NULL)        ← Raíz
│   ├── Subcategoría "Nacional" (id=4, parent_id=1)  ← Hijo
│   └── Subcategoría "Internacional" (id=5, parent_id=1)
├── Categoría "Pagos" (id=2, parent_id=NULL)         ← Raíz
└── Categoría "Devoluciones" (id=3, parent_id=NULL)  ← Raíz
```

---

### Tabla: faq_items

**Propósito:** Almacena las preguntas frecuentes con traducciones multi-idioma en JSONB.

```sql
CREATE TABLE faq_items (
    id                BIGSERIAL PRIMARY KEY,
    account_id        BIGINT NOT NULL REFERENCES accounts(id),
    faq_category_id   BIGINT REFERENCES faq_categories(id),
    position          INTEGER NOT NULL DEFAULT 0,
    is_visible        BOOLEAN NOT NULL DEFAULT TRUE,
    translations      JSONB NOT NULL DEFAULT '{}',
    created_by_id     BIGINT REFERENCES users(id),
    updated_by_id     BIGINT REFERENCES users(id),
    created_at        TIMESTAMP NOT NULL,
    updated_at        TIMESTAMP NOT NULL
);

-- Índices para optimizar consultas
CREATE INDEX idx_faq_items_account_id ON faq_items(account_id);
CREATE INDEX idx_faq_items_faq_category_id ON faq_items(faq_category_id);
CREATE INDEX idx_faq_items_account_category ON faq_items(account_id, faq_category_id);
CREATE INDEX idx_faq_items_account_position ON faq_items(account_id, position);
CREATE INDEX idx_faq_items_is_visible ON faq_items(is_visible);
CREATE INDEX idx_faq_items_translations ON faq_items USING GIN(translations);  -- Búsqueda en JSONB
```

**Descripción de Columnas:**

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| `id` | BIGSERIAL | NO | auto | Identificador único |
| `account_id` | BIGINT | NO | - | FK a `accounts`. Aísla datos por cuenta |
| `faq_category_id` | BIGINT | SÍ | NULL | FK a `faq_categories`. Categoría padre |
| `position` | INTEGER | NO | 0 | Orden dentro de la categoría |
| `is_visible` | BOOLEAN | NO | TRUE | Si el bot puede ver esta FAQ |
| `translations` | JSONB | NO | {} | Traducciones multi-idioma |
| `created_by_id` | BIGINT | SÍ | NULL | FK a `users`. Quién creó |
| `updated_by_id` | BIGINT | SÍ | NULL | FK a `users`. Última modificación |
| `created_at` | TIMESTAMP | NO | auto | Fecha de creación |
| `updated_at` | TIMESTAMP | NO | auto | Última actualización |

**Estructura del Campo `translations` (JSONB):**

```json
{
  "es": {
    "question": "¿Cuánto tiempo tarda el envío?",
    "answer": "El envío estándar tarda de 3 a 5 días hábiles. Para envíos express, el tiempo es de 24-48 horas."
  },
  "en": {
    "question": "How long does shipping take?",
    "answer": "Standard shipping takes 3-5 business days. For express shipping, it takes 24-48 hours."
  }
}
```

**¿Por qué JSONB?**
- Flexibilidad para agregar idiomas sin modificar esquema
- Índice GIN permite búsquedas eficientes en el contenido
- Consultas como `WHERE translations::text ILIKE '%envío%'`

---

### Tabla: inbox_faq_categories

**Propósito:** Tabla de unión (join table) que conecta inboxes con categorías de FAQs. Relación muchos-a-muchos.

```sql
CREATE TABLE inbox_faq_categories (
    id                BIGSERIAL PRIMARY KEY,
    inbox_id          BIGINT NOT NULL REFERENCES inboxes(id),
    faq_category_id   BIGINT NOT NULL REFERENCES faq_categories(id),
    created_at        TIMESTAMP NOT NULL,
    updated_at        TIMESTAMP NOT NULL,

    -- Constraint único para evitar duplicados
    CONSTRAINT idx_inbox_faq_unique UNIQUE (inbox_id, faq_category_id)
);

-- Índice compuesto único
CREATE UNIQUE INDEX idx_inbox_faq_categories_unique ON inbox_faq_categories(inbox_id, faq_category_id);
```

**Descripción de Columnas:**

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| `id` | BIGSERIAL | NO | auto | Identificador único |
| `inbox_id` | BIGINT | NO | - | FK a `inboxes`. Canal de comunicación |
| `faq_category_id` | BIGINT | NO | - | FK a `faq_categories`. Categoría asignada |
| `created_at` | TIMESTAMP | NO | auto | Fecha de asociación |
| `updated_at` | TIMESTAMP | NO | auto | Última actualización |

**Ejemplo de Datos:**

```
┌────┬──────────┬─────────────────┐
│ id │ inbox_id │ faq_category_id │
├────┼──────────┼─────────────────┤
│  1 │        5 │               1 │  ← Inbox WhatsApp #5 tiene acceso a "Envíos"
│  2 │        5 │               2 │  ← Inbox WhatsApp #5 tiene acceso a "Pagos"
│  3 │        7 │               1 │  ← Inbox Web #7 tiene acceso a "Envíos"
│  4 │        7 │               3 │  ← Inbox Web #7 tiene acceso a "Devoluciones"
└────┴──────────┴─────────────────┘
```

**Propósito de la Relación:**
- Permite configurar qué FAQs ve cada canal (WhatsApp, Web, etc.)
- Un inbox puede tener múltiples categorías
- Una categoría puede estar en múltiples inboxes
- El bot solo consulta FAQs de categorías asignadas a su inbox

---

### Resumen de Relaciones

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              RESUMEN DE RELACIONES                              │
└─────────────────────────────────────────────────────────────────────────────────┘

  TABLA                      RELACIÓN                         TABLA DESTINO
  ═════                      ════════                         ═════════════

  faq_categories ──────────► belongs_to ──────────────────► accounts (1:N)
  faq_categories ──────────► belongs_to ──────────────────► faq_categories (self, árbol)
  faq_categories ──────────► has_many ─────────────────────► faq_items (1:N)
  faq_categories ──────────► has_many ─────────────────────► inbox_faq_categories (1:N)
  faq_categories ──────────► has_many :inboxes, through ───► inboxes (N:M)

  faq_items ───────────────► belongs_to ──────────────────► accounts (1:N)
  faq_items ───────────────► belongs_to ──────────────────► faq_categories (1:N)
  faq_items ───────────────► belongs_to ──────────────────► users (created_by)
  faq_items ───────────────► belongs_to ──────────────────► users (updated_by)

  inbox_faq_categories ────► belongs_to ──────────────────► inboxes (N:1)
  inbox_faq_categories ────► belongs_to ──────────────────► faq_categories (N:1)

  inboxes ─────────────────► has_many ─────────────────────► inbox_faq_categories (1:N)
  inboxes ─────────────────► has_many :faq_categories, through ► faq_categories (N:M)
```

---

## Endpoints para Administradores

Requieren autenticación de usuario con permisos de administrador.

### FAQ Categories

#### Listar Categorías
```http
GET /api/v1/accounts/:account_id/faq_categories
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Envíos",
    "description": "Preguntas sobre envíos",
    "parent_id": null,
    "position": 0,
    "is_visible": true,
    "children": [
      {
        "id": 2,
        "name": "Envíos Internacionales",
        "parent_id": 1
      }
    ]
  }
]
```

#### Árbol de Categorías (Paginado)
```http
GET /api/v1/accounts/:account_id/faq_categories/tree
```

**Query Parameters:**
| Param | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `page` | integer | 1 | Página actual |
| `per_page` | integer | 5 | Categorías por página |
| `q` | string | - | Búsqueda en nombre de categoría o contenido FAQ |

**Response:**
```json
{
  "data": [...],
  "meta": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 15
  }
}
```

#### Obtener Categoría
```http
GET /api/v1/accounts/:account_id/faq_categories/:id
```

#### Crear Categoría
```http
POST /api/v1/accounts/:account_id/faq_categories
```

**Body:**
```json
{
  "faq_category": {
    "name": "Nueva Categoría",
    "description": "Descripción opcional",
    "parent_id": null,
    "position": 0,
    "is_visible": true
  }
}
```

**Rate Limit:** 3 segundos entre creaciones

#### Actualizar Categoría
```http
PATCH /api/v1/accounts/:account_id/faq_categories/:id
```

#### Eliminar Categoría
```http
DELETE /api/v1/accounts/:account_id/faq_categories/:id
```

> **Advertencia:** Eliminar una categoría también elimina todas sus subcategorías y FAQs (CASCADE).

#### Toggle Visibilidad
```http
POST /api/v1/accounts/:account_id/faq_categories/:id/toggle_visibility
```

#### Mover Categoría
```http
POST /api/v1/accounts/:account_id/faq_categories/:id/move
```

**Body:**
```json
{
  "parent_id": 5,
  "position": 2
}
```

---

### FAQ Items

#### Listar FAQs
```http
GET /api/v1/accounts/:account_id/faq_items
```

**Query Parameters:**
| Param | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `page` | integer | 1 | Página actual |
| `per_page` | integer | 50 | FAQs por página |
| `category_id` | integer | - | Filtrar por categoría |
| `q` | string | - | Búsqueda en pregunta/respuesta |

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "faq_category_id": 1,
      "position": 0,
      "is_visible": true,
      "translations": {
        "es": {
          "question": "¿Cuánto tarda el envío?",
          "answer": "El envío tarda de 3 a 5 días hábiles."
        },
        "en": {
          "question": "How long does shipping take?",
          "answer": "Shipping takes 3 to 5 business days."
        }
      },
      "primary_question": "¿Cuánto tarda el envío?",
      "primary_answer": "El envío tarda de 3 a 5 días hábiles.",
      "created_at": "2025-12-25T10:00:00Z",
      "updated_at": "2025-12-25T10:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 2,
    "total_count": 25
  }
}
```

#### Obtener FAQ
```http
GET /api/v1/accounts/:account_id/faq_items/:id
```

#### Crear FAQ
```http
POST /api/v1/accounts/:account_id/faq_items
```

**Body:**
```json
{
  "faq_item": {
    "faq_category_id": 1,
    "position": 0,
    "is_visible": true,
    "translations": {
      "es": {
        "question": "¿Cuánto tarda el envío?",
        "answer": "El envío tarda de 3 a 5 días hábiles."
      },
      "en": {
        "question": "How long does shipping take?",
        "answer": "Shipping takes 3 to 5 business days."
      }
    }
  }
}
```

**Rate Limit:** 3 segundos entre creaciones

#### Actualizar FAQ
```http
PATCH /api/v1/accounts/:account_id/faq_items/:id
```

#### Eliminar FAQ
```http
DELETE /api/v1/accounts/:account_id/faq_items/:id
```

#### Eliminar Múltiples FAQs
```http
POST /api/v1/accounts/:account_id/faq_items/bulk_delete
```

**Body:**
```json
{
  "ids": [1, 2, 3]
}
```

#### Toggle Visibilidad
```http
POST /api/v1/accounts/:account_id/faq_items/:id/toggle_visibility
```

#### Mover FAQ (Reordenar)
```http
POST /api/v1/accounts/:account_id/faq_items/:id/move
```

**Body:**
```json
{
  "direction": "up"
}
```

---

### Inbox FAQ Configuration

Configurar qué categorías de FAQs están disponibles para un inbox (canal WhatsApp).

#### Listar Categorías del Inbox
```http
GET /api/v1/accounts/:account_id/inboxes/:inbox_id/faq_categories
```

**Response:**
```json
{
  "data": [
    { "id": 1, "name": "Envíos" },
    { "id": 2, "name": "Pagos" }
  ]
}
```

#### Configurar Categorías del Inbox
```http
POST /api/v1/accounts/:account_id/inboxes/:inbox_id/faq_categories
```

**Body:**
```json
{
  "faq_category_ids": [1, 2, 5]
}
```

---

## Endpoint para Bot

### Bot FAQs

Endpoint optimizado para consultas del bot. Retorna todas las FAQs visibles asociadas al inbox en una sola llamada.

```http
GET /api/v1/accounts/:account_id/inboxes/:inbox_id/bot_faqs
```

**Autenticación:**
- Header: `X-Bot-Token: <agent_bot_access_token>`
- O Query param: `?bot_token=<agent_bot_access_token>`

**Query Parameters:**
| Param | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `locale` | string | `es` | Idioma preferido (`es`, `en`). Fallback automático a `en` |
| `q` | string | - | Búsqueda en pregunta/respuesta |
| `category_id` | integer | - | Filtrar por categoría específica |

**Response:**
```json
{
  "locale": "es",
  "inbox_id": 1,
  "categories": [
    { "id": 1, "name": "Envíos", "parent_id": null },
    { "id": 2, "name": "Envíos Internacionales", "parent_id": 1 },
    { "id": 3, "name": "Pagos", "parent_id": null }
  ],
  "faqs": [
    {
      "id": 1,
      "category_id": 1,
      "category": "Envíos",
      "question": "¿Cuánto tarda el envío?",
      "answer": "El envío tarda de 3 a 5 días hábiles.",
      "position": 0
    },
    {
      "id": 2,
      "category_id": 1,
      "category": "Envíos",
      "question": "¿Cuál es el costo de envío?",
      "answer": "El costo de envío es de $50 MXN para todo México.",
      "position": 1
    },
    {
      "id": 3,
      "category_id": 3,
      "category": "Pagos",
      "question": "¿Qué métodos de pago aceptan?",
      "answer": "Aceptamos tarjetas de crédito, débito, PayPal y transferencia bancaria.",
      "position": 0
    }
  ],
  "total": 3,
  "last_updated": "2025-12-25T10:30:00Z"
}
```

**Características:**
- Solo retorna FAQs con `is_visible: true`
- Solo retorna FAQs de categorías asociadas al inbox
- Incluye automáticamente FAQs de subcategorías
- Estructura plana optimizada para búsqueda rápida
- Sin paginación (todo en memoria para el bot)
- Fallback automático de idioma (`es` -> `en`)

**Ejemplo de uso con cURL:**
```bash
curl -X GET \
  "https://app.example.com/api/v1/accounts/1/inboxes/5/bot_faqs?locale=es" \
  -H "X-Bot-Token: your_bot_access_token"
```

**Ejemplo con búsqueda:**
```bash
curl -X GET \
  "https://app.example.com/api/v1/accounts/1/inboxes/5/bot_faqs?locale=es&q=envío" \
  -H "X-Bot-Token: your_bot_access_token"
```

---

## Ejemplos de Uso

### Flujo típico del Bot

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           FLUJO DE CONSULTA DEL BOT                             │
└─────────────────────────────────────────────────────────────────────────────────┘

     USUARIO                        BOT                           API
     ═══════                       ═════                         ═════
        │                            │                             │
        │  "Hola, tengo una duda"    │                             │
        │ ──────────────────────────►│                             │
        │                            │                             │
        │                            │  GET /bot_faqs?locale=es    │
        │                            │ ───────────────────────────►│
        │                            │                             │
        │                            │  { faqs: [...], total: 25 } │
        │                            │ ◄───────────────────────────│
        │                            │                             │
        │                            │  (Bot analiza pregunta y    │
        │                            │   busca en FAQs localmente) │
        │                            │                             │
        │  "¿Cuánto tarda el envío?" │                             │
        │ ──────────────────────────►│                             │
        │                            │                             │
        │                            │  (Match en FAQ #1)          │
        │                            │                             │
        │  "El envío tarda de 3-5    │                             │
        │   días hábiles..."         │                             │
        │ ◄──────────────────────────│                             │
        │                            │                             │
```

### Configuración desde el Dashboard

1. **Crear categorías** desde el panel de administración
2. **Agregar FAQs** con traducciones en español e inglés
3. **Configurar inbox** asignando las categorías relevantes
4. **El bot automáticamente** tendrá acceso a las FAQs configuradas

---

## Códigos de Error

| Código | Descripción |
|--------|-------------|
| 401 | No autorizado - Token de bot inválido o faltante |
| 403 | Prohibido - Sin permisos para esta acción |
| 404 | No encontrado - Recurso no existe |
| 422 | Error de validación - Datos inválidos |
| 429 | Rate limit - Esperar antes de reintentar |

**Ejemplo de error 429:**
```json
{
  "error": "Rate limit exceeded. Please wait 3 seconds before trying again.",
  "retry_after": 3
}
```

---

## Notas de Implementación

- **Ordenamiento:** Las categorías raíz se ordenan por `created_at ASC` (más antiguas primero)
- **FAQs:** Se ordenan por `position ASC`, luego `created_at ASC`
- **Rate Limiting:** Solo aplica a operaciones de creación (3 segundos)
- **Idiomas soportados:** Español (`es`) e Inglés (`en`)
- **Fallback de idioma:** Si no existe traducción en el idioma solicitado, se usa inglés
- **Índice GIN:** Permite búsquedas eficientes en el campo JSONB `translations`
- **Cascade Delete:** Al eliminar una categoría, se eliminan sus subcategorías y FAQs automáticamente
