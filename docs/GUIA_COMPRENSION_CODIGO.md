# Guía de Comprensión del Código - Chatwoot

## 📖 Introducción

Chatwoot es una plataforma moderna de soporte al cliente open-source, que actúa como alternativa a Intercom, Zendesk y Salesforce Service Cloud. Este fork está diseñado para ser una referencia modificable del proyecto original.

## 🏗️ Arquitectura General

### Stack Tecnológico
- **Backend**: Ruby on Rails 7.x con PostgreSQL (+ pgvector para AI)
- **Frontend**: Vue.js 3.5.12 con Vuex, Vue Router
- **Build Tools**: Vite 5.4.20, pnpm 10.x
- **Background Jobs**: Sidekiq con Redis
- **Testing**: Vitest (frontend), RSpec (backend)
- **Containerización**: Docker con docker-compose

### Arquitectura Técnica
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Vue.js SPA    │    │  Ruby on Rails  │    │   PostgreSQL    │
│   (Frontend)    │◄──►│    (Backend)    │◄──►│   + pgvector    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ▲                       ▲                       ▲
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      Vite       │    │     Sidekiq     │    │      Redis      │
│  (Dev Server)   │    │ (Background     │    │   (Cache +      │
│                 │    │    Jobs)        │    │    Jobs)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Estructura de Carpetas

### Carpetas Principales

```
chatwoot/
├── app/                    # Código principal de la aplicación Rails
│   ├── controllers/        # Controladores API y web
│   ├── models/            # Modelos de datos (ActiveRecord)
│   ├── services/          # Lógica de negocio (Service Objects)
│   ├── jobs/              # Background jobs (Sidekiq)
│   ├── javascript/        # Frontend Vue.js completo
│   │   ├── dashboard/     # Panel principal de administración
│   │   ├── widget/        # Widget de chat embebible
│   │   ├── portal/        # Help center público
│   │   ├── sdk/           # SDK para desarrolladores
│   │   └── shared/        # Componentes compartidos
│   ├── views/             # Templates Rails (mayormente APIs)
│   └── workers/           # Workers de Sidekiq
├── config/                # Configuración Rails
├── db/                    # Migraciones y schema de BD
├── docs/                  # Documentación del proyecto
├── spec/                  # Tests (RSpec para backend)
├── public/                # Assets estáticos compilados
└── .devcontainer/         # Configuración Dev Container
```

### Frontend Detallado (app/javascript/)

```
app/javascript/
├── dashboard/             # 🏢 Panel de administración principal
│   ├── routes/           # Rutas Vue Router
│   ├── store/            # Estado Vuex
│   ├── components/       # Componentes Vue
│   └── pages/            # Páginas principales
├── widget/               # 💬 Widget de chat embebible
├── portal/               # 📚 Help center público
├── sdk/                  # 🔧 SDK para desarrolladores
├── shared/               # 🔄 Componentes compartidos
├── design-system/        # 🎨 Sistema de diseño
└── v3/                   # 🆕 Nueva versión de UI
```

## 🔍 Componentes Clave

### Backend (Ruby on Rails)

#### Controllers (`app/controllers/`)
- **API Controllers**: Manejan requests del frontend Vue.js
- **Public Controllers**: Endpoints públicos (widget, portal)
- **Platform Controllers**: API para integraciones externas

#### Models (`app/models/`)
- **Account**: Organización/empresa usando Chatwoot
- **User**: Usuarios del sistema (agentes, administradores)
- **Contact**: Clientes que contactan soporte
- **Conversation**: Hilos de conversación
- **Message**: Mensajes individuales
- **Inbox**: Canales de comunicación (email, chat, WhatsApp, etc.)

#### Services (`app/services/`)
Lógica de negocio encapsulada:
- **ContactBuilder**: Creación y actualización de contactos
- **MessageBuilder**: Procesamiento de mensajes
- **ConversationFinder**: Búsqueda de conversaciones
- **NotificationService**: Sistema de notificaciones

#### Jobs (`app/jobs/`)
Tareas asíncronas:
- **SendEmailJob**: Envío de emails
- **WebhookJob**: Procesamiento de webhooks
- **AnalyticsJob**: Procesamiento de métricas

### Frontend (Vue.js)

#### Dashboard Principal
- **Conversaciones**: Inbox unificado de todos los canales
- **Contactos**: Gestión de clientes
- **Reportes**: Analytics y métricas
- **Configuración**: Administración de cuenta

#### Widget Embebible
- **Chat Widget**: Componente embebible en sitios web
- **Configuración**: Personalización de apariencia
- **API Integration**: Conexión con backend

## 🛠️ Patrones de Desarrollo

### Backend Patterns

1. **Service Objects**: Lógica de negocio en `app/services/`
2. **Form Objects**: Validación y procesamiento de forms
3. **Policy Objects**: Autorización con Pundit
4. **Presenter Objects**: Formateo de datos para frontend

### Frontend Patterns

1. **Vuex Store**: Estado centralizado por módulos
2. **Component Composition**: Componentes reutilizables
3. **API Layer**: Abstracción de llamadas HTTP
4. **Route Guards**: Protección de rutas

## 🔧 Flujos de Desarrollo Comunes

### Agregar Nueva Funcionalidad

1. **Backend**:
   ```
   Modelo → Migración → Controlador → Servicio → Tests
   ```

2. **Frontend**:
   ```
   Ruta → Store Module → Componente → API Call → Tests
   ```

### Modificar Funcionalidad Existente

1. **Identificar componentes**: Usar grep/búsqueda para encontrar archivos relevantes
2. **Backend**: Modificar service objects antes que controladores
3. **Frontend**: Modificar store antes que componentes
4. **Tests**: Actualizar tests correspondientes

## 📍 Puntos de Entrada Clave

### Para Nuevas Funcionalidades
- **Backend**: `app/controllers/api/v1/` (APIs)
- **Frontend**: `app/javascript/dashboard/` (UI principal)

### Para Integraciones
- **Webhooks**: `app/controllers/webhooks/`
- **APIs Públicas**: `app/controllers/public/api/`
- **SDK**: `app/javascript/sdk/`

### Para Personalización UI
- **Design System**: `app/javascript/design-system/`
- **Componentes Shared**: `app/javascript/shared/`
- **Estilos**: Buscar archivos `.scss` en cada módulo

## 🚨 Consideraciones Importantes

### Modificaciones Sin Afectar Core

1. **Usa Service Objects**: Crea nuevos servicios en lugar de modificar existentes
2. **Extiende Models**: Usa concerns y modules para agregar funcionalidad
3. **Componentes Nuevos**: Crea componentes nuevos en lugar de modificar existentes
4. **Environment Variables**: Usa ENV vars para configuraciones específicas

### Buenas Prácticas

1. **Tests**: Siempre agregar tests para nuevas funcionalidades
2. **Migraciones**: Usar migraciones reversibles
3. **API Versioning**: Mantener retrocompatibilidad en APIs
4. **Componentes**: Seguir convenciones de naming de Vue.js
5. **Estado**: Minimizar mutaciones directas del store

## 🔍 Comandos Útiles para Exploración

```bash
# Buscar en código Ruby
grep -r "class.*Controller" app/controllers/

# Buscar componentes Vue
find app/javascript -name "*.vue" | grep -i component_name

# Buscar servicios específicos
ls app/services/*service*

# Ver rutas Rails
bundle exec rails routes | grep api

# Ver rutas Vue
grep -r "path:" app/javascript/dashboard/routes/
```

## 🎯 Próximos Pasos

1. **Configurar ambiente de desarrollo** (ver guía de instalación)
2. **Explorar dashboard Vue.js** en modo desarrollo
3. **Revisar APIs principales** en `app/controllers/api/v1/`
4. **Entender flujo de mensajes** siguiendo `MessageBuilder` service
5. **Personalizar según necesidades específicas**

---

Esta guía te ayudará a navegar y entender la estructura de Chatwoot. Para modificaciones específicas, siempre busca primero componentes similares existentes para mantener consistencia con el patrón del proyecto.