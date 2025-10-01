# GP Bikes AI Assistant - Guía de Setup n8n

**Documento:** Guía paso a paso para configurar n8n + Chatwoot
**Fecha:** 30 de septiembre de 2025
**Versión:** 1.0
**Tiempo estimado:** 2-3 horas

---

## 📋 Tabla de Contenidos

1. [Pre-requisitos](#pre-requisitos)
2. [Paso 1: Docker Compose Setup](#paso-1-docker-compose-setup)
3. [Paso 2: Configurar Chatwoot Webhook](#paso-2-configurar-chatwoot-webhook)
4. [Paso 3: Importar Workflows n8n](#paso-3-importar-workflows-n8n)
5. [Paso 4: Configurar Credenciales OpenAI](#paso-4-configurar-credenciales-openai)
6. [Paso 5: Activar Workflows](#paso-5-activar-workflows)
7. [Paso 6: Testing End-to-End](#paso-6-testing-end-to-end)
8. [Troubleshooting](#troubleshooting)

---

## Pre-requisitos

### Software Requerido

- **Docker Desktop** >= 4.0 ([descargar](https://www.docker.com/products/docker-desktop))
- **Git** ([descargar](https://git-scm.com/downloads))
- **Node.js** >= 18 (para npm scripts) ([descargar](https://nodejs.org/))
- **8GB RAM** mínimo disponible

### Credenciales Requeridas

- **OpenAI API Key** ([obtener aquí](https://platform.openai.com/api-keys))
  - Budget mínimo: $50 USD
  - Rate limit recomendado: 10 RPM (requests per minute)

- **WhatsApp Business API** (opcional para testing local)
  - Phone Number ID
  - Access Token
  - Webhook Verify Token

### Verificación Pre-requisitos

```bash
# Verificar Docker
docker --version
# Docker version 24.0.0 o superior ✅

# Verificar Docker está corriendo
docker ps
# Debe mostrar tabla de containers (puede estar vacía) ✅

# Verificar Git
git --version
# git version 2.30.0 o superior ✅

# Verificar Node.js
node --version
# v18.0.0 o superior ✅
```

---

## Paso 1: Docker Compose Setup

### 1.1 Clonar Repositorio

```bash
# Clonar repo
git clone https://github.com/Matias0032/crm-agents.git
cd "GP Bikes"
```

### 1.2 Configurar Variables de Entorno

```bash
# Copiar archivo de ejemplo
cp .env.development.example .env.development

# Editar con tu editor favorito
nano .env.development  # o vim, vscode, etc.
```

**Variables críticas a configurar:**

```bash
# ============================================================================
# OpenAI API (OBLIGATORIO)
# ============================================================================
OPENAI_API_KEY=sk-proj-YOUR-ACTUAL-KEY-HERE
OPENAI_ORG_ID=org-YOUR-ORG-ID-HERE  # Opcional
OPENAI_MODEL=gpt-4  # o gpt-4-turbo, gpt-3.5-turbo

# ============================================================================
# PostgreSQL Database (ya configurado por defecto)
# ============================================================================
DATABASE_URL=postgresql://postgres:Yu9oHfzO7DcCZxLzYeKaO7JnfRvWQJrQ@localhost:5432/chatwoot_dev
POSTGRES_PASSWORD=Yu9oHfzO7DcCZxLzYeKaO7JnfRvWQJrQ

# ============================================================================
# n8n Configuration (auto-configurado)
# ============================================================================
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=gpbikes2025  # Cambiar en producción
N8N_ENCRYPTION_KEY=<generate-random-key-here>
```

**Generar N8N_ENCRYPTION_KEY:**
```bash
# En macOS/Linux
openssl rand -base64 32

# Copiar el output y pegarlo en .env.development
N8N_ENCRYPTION_KEY=aB3kF7mP9qR2sT5vW8xY1zC4dE6gH0jK=
```

### 1.3 Levantar Servicios Docker

```bash
# Levantar PostgreSQL, Redis, Chatwoot y n8n
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f
```

**Output esperado:**
```
✅ postgres     | database system is ready to accept connections
✅ redis        | Ready to accept connections
✅ chatwoot_web | Listening on 0.0.0.0:3000
✅ n8n          | Editor is now accessible via: http://localhost:5678
```

**Si hay errores:**
```bash
# Ver logs específicos
docker-compose logs chatwoot_web
docker-compose logs n8n
```

### 1.4 Crear Base de Datos Chatwoot

```bash
# Crear database
docker-compose exec chatwoot bundle exec rails db:create

# Ejecutar migraciones
docker-compose exec chatwoot bundle exec rails db:migrate

# Seed inicial (usuario admin test)
docker-compose exec chatwoot bundle exec rails db:seed

# Output esperado:
# Account created with email: john@acme.inc, password: Password1!
```

### 1.5 Verificar Servicios

```bash
# 1. Chatwoot (debe cargar dashboard)
open http://localhost:3000

# 2. n8n (debe cargar login page)
open http://localhost:5678

# 3. PostgreSQL (debe aceptar conexiones)
docker-compose exec postgres psql -U postgres -c "SELECT version();"

# 4. Redis (debe responder PONG)
docker-compose exec redis redis-cli ping
```

✅ **Checkpoint:** Todos los servicios corriendo correctamente

---

## Paso 2: Configurar Chatwoot Webhook

### 2.1 Login a Chatwoot

1. Abrir http://localhost:3000
2. Credenciales iniciales:
   - **Email:** `john@acme.inc`
   - **Password:** `Password1!`

### 2.2 Crear Webhook

**Navegación:** Settings → Integrations → Webhooks

1. Click **"Configure"** en la card de Webhooks

2. Click **"Add new webhook"**

3. Configurar webhook:
   ```
   URL: http://n8n:5678/webhook/chatwoot-messages
   ```

   **Importante:** Usar `http://n8n:5678` (hostname Docker) NO `http://localhost:5678`

4. Seleccionar eventos:
   - ✅ **Message Created** (obligatorio)
   - ✅ **Conversation Updated** (recomendado)
   - ⬜ Conversation Created (opcional)

5. Click **"Create"**

### 2.3 Verificar Webhook

```bash
# Ver logs de Chatwoot para confirmar webhook configurado
docker-compose logs chatwoot_web | grep -i webhook

# Output esperado:
# Webhook created: http://n8n:5678/webhook/chatwoot-messages
```

✅ **Checkpoint:** Webhook configurado en Chatwoot

---

## Paso 3: Importar Workflows n8n

### 3.1 Login a n8n

1. Abrir http://localhost:5678
2. Crear cuenta admin:
   - **Email:** `admin@gpbikes.local`
   - **Password:** `gpbikes2025` (cambiar en producción)
   - **First Name:** `Admin`
   - **Last Name:** `GP Bikes`

### 3.2 Importar Workflow "Message Router"

**Opción A: Crear manualmente (recomendado para aprendizaje)**

1. Click **"Add workflow"** (botón +)
2. Nombrar: `Message Router`
3. Agregar nodes:

**Node 1: Webhook**
```
Trigger: Webhook
HTTP Method: POST
Path: chatwoot-messages
Respond: Immediately
Response Code: 200
```

**Node 2: Function - Extract Data**
```javascript
// Extraer datos del webhook Chatwoot
const conversation_id = $json.conversation.id;
const message = $json.content;
const contact_id = $json.sender.id;
const messages_count = $json.conversation.messages_count;

return {
  conversation_id,
  message,
  contact_id,
  messages_count,
  full_payload: $json
};
```

**Node 3: Switch - Route to Workers**
```
Mode: Rules
Output: Multiple

Rule 1: {{ $json.messages_count }} == 1
  → Connect to: GreetingWorker (workflow trigger)

Rule 2: {{ $json.message }} matches regex (moto|modelo|MT-|FZ|XTZ)
  → Connect to: ProductCatalogWorker

Rule 3: {{ $json.message }} matches regex (cita|taller|mantenimiento)
  → Connect to: ServiceSchedulingWorker

Rule 4: {{ $json.message }} matches regex (financiamiento|cuotas|crédito)
  → Connect to: FinancingWorker

Default (fallback):
  → Connect to: HumanHandoffWorker
```

4. **Save** workflow (Ctrl+S o CMD+S)

**Opción B: Importar desde archivo JSON**

```bash
# Si tienes workflows exportados en n8n-workflows/
# 1. En n8n UI: Click menú (tres puntos) → Import from File
# 2. Seleccionar: n8n-workflows/MessageRouter.json
# 3. Click "Import"
```

### 3.3 Crear Workflow "GreetingWorker"

1. **New workflow** → Nombrar: `GreetingWorker`

**Node 1: Execute Workflow Trigger**
```
Source Workflow: Message Router
```

**Node 2: HTTP Request - Get Contact**
```
Method: GET
URL: http://chatwoot:3000/api/v1/accounts/1/contacts/{{ $json.contact_id }}
Authentication: Generic Credential Type
  - Name: api_access_token
  - Value: (obtener desde Chatwoot → Profile → Access Token)
```

**Node 3: OpenAI Chat**
```
Resource: Message
Model: gpt-4
Prompt:
"""
Eres un asistente de GP Bikes Yamaha Colombia.
Cliente dice: "{{ $('Execute Workflow Trigger').item.json.message }}"

Tu trabajo:
1. Saluda cordialmente
2. Preséntate como asistente de GP Bikes Yamaha
3. Si el cliente menciona su nombre, úsalo
4. Pregunta cómo puedes ayudar

Horarios: Lunes a Sábado 9:00am - 6:00pm
Responde en español colombiano, máximo 150 palabras.
"""

Temperature: 0.7
Max Tokens: 150
```

**Node 4: HTTP Request - Send Message**
```
Method: POST
URL: http://chatwoot:3000/api/v1/accounts/1/conversations/{{ $('Execute Workflow Trigger').item.json.conversation_id }}/messages
Authentication: api_access_token (same as Node 2)
Body (JSON):
{
  "content": "{{ $json.choices[0].message.content }}",
  "message_type": "outgoing",
  "private": false
}
```

**Node 5: HTTP Request - Update Custom Attributes**
```
Method: PUT
URL: http://chatwoot:3000/api/v1/accounts/1/contacts/{{ $('Execute Workflow Trigger').item.json.contact_id }}
Body (JSON):
{
  "custom_attributes": {
    "greeted": true,
    "last_interaction_date": "{{ $now.toISOString() }}",
    "last_worker": "GreetingWorker"
  }
}
```

5. **Save** workflow

---

## Paso 4: Configurar Credenciales OpenAI

### 4.1 Crear Credencial OpenAI en n8n

1. En n8n UI: Click **Settings** (gear icon) → **Credentials**
2. Click **"Add Credential"**
3. Buscar: `OpenAI`
4. Configurar:
   ```
   Name: OpenAI GP Bikes
   API Key: sk-proj-YOUR-KEY-HERE
   Organization ID: (opcional)
   ```
5. Click **"Save"**

### 4.2 Asignar Credencial a Workflows

1. Abrir workflow `GreetingWorker`
2. Click en node **"OpenAI Chat"**
3. En campo **"Credential to connect with":**
   - Select: `OpenAI GP Bikes`
4. **Save** workflow

### 4.3 Crear Credencial Chatwoot API

1. **Obtener API Access Token:**
   - En Chatwoot: Profile (avatar) → Profile Settings
   - Tab **"Access Token"**
   - Click **"Copy"**

2. **En n8n:**
   - Settings → Credentials → Add Credential
   - Tipo: **Generic Credential Type**
   - Name: `Chatwoot API Token`
   - Add field:
     ```
     Name: api_access_token
     Value: <paste-token-aquí>
     ```
   - Save

3. **Asignar a HTTP Request nodes:**
   - En workflow GreetingWorker
   - Para cada HTTP Request node (GET Contact, POST Message, PUT Custom Attributes):
     - Authentication: Generic Credential Type
     - Credential: `Chatwoot API Token`

---

## Paso 5: Activar Workflows

### 5.1 Activar Message Router

1. Abrir workflow `Message Router`
2. Toggle **"Active"** (arriba a la derecha) → ON (verde)
3. Verificar status: **"Active"** badge

### 5.2 Activar GreetingWorker

1. Abrir workflow `GreetingWorker`
2. Toggle **"Active"** → ON
3. Verificar status: **"Active"**

### 5.3 Verificar Workflows Activos

```bash
# Via n8n API
curl -X GET http://localhost:5678/api/v1/workflows \
  -H "X-N8N-API-KEY: YOUR-API-KEY" | jq '.[] | {name, active}'

# Output esperado:
# {
#   "name": "Message Router",
#   "active": true
# }
# {
#   "name": "GreetingWorker",
#   "active": true
# }
```

✅ **Checkpoint:** Workflows activos y listos para recibir webhooks

---

## Paso 6: Testing End-to-End

### 6.1 Test Manual desde Chatwoot UI

1. **Crear conversación de prueba:**
   - Chatwoot → Conversations
   - Click **"New Conversation"**
   - Select inbox: (crear inbox test si no existe)
   - Contact: Create new contact
     ```
     Name: Test Cliente
     Email: test@gpbikes.com
     Phone: +57300123456
     ```

2. **Enviar mensaje:**
   ```
   Hola, me llamo Juan y quiero información sobre motos Yamaha
   ```

3. **Verificar respuesta:**
   - Esperar 2-3 segundos
   - Debe aparecer respuesta automática del GreetingWorker:
     ```
     Hola Juan! 👋 Soy tu asistente virtual de GP Bikes Yamaha Colombia.

     Es un placer atenderte. Estamos especializados en motos Yamaha de alta calidad.

     ¿En qué puedo ayudarte hoy? ¿Te interesa algún modelo en particular, necesitas agendar
     una cita de taller, o quieres información sobre financiamiento?

     Nuestro horario de atención es Lunes a Sábado de 9:00am a 6:00pm.
     ```

4. **Verificar custom_attributes:**
   - Click en contacto (sidebar derecha)
   - Scroll down a **"Custom Attributes"**
   - Debe mostrar:
     ```yaml
     greeted: true
     last_interaction_date: 2025-09-30T22:30:15Z
     last_worker: GreetingWorker
     ```

### 6.2 Test desde n8n Executions

1. **Ver ejecución en n8n:**
   - n8n UI → Executions (tab superior)
   - Buscar ejecución de `Message Router`
   - Click para ver detalles
   - Verificar:
     - ✅ Webhook triggered
     - ✅ Routed to GreetingWorker
     - ✅ OpenAI called successfully
     - ✅ Message sent to Chatwoot
     - ✅ Custom attributes updated

2. **Debugging si falla:**
   - Click en node que falló (marcado en rojo)
   - Ver **"Error"** tab
   - Revisar **"Input"** y **"Output"** tabs

### 6.3 Test con curl (API directa)

```bash
# Obtener conversation_id y contact_id desde Chatwoot UI
CONVERSATION_ID=123
API_TOKEN="your-chatwoot-api-token"

# Enviar mensaje de prueba
curl -X POST http://localhost:3000/api/v1/accounts/1/conversations/$CONVERSATION_ID/messages \
  -H "Content-Type: application/json" \
  -H "api_access_token: $API_TOKEN" \
  -d '{
    "content": "Hola, soy María y necesito una moto para trabajo",
    "message_type": "incoming"
  }'

# Verificar en n8n executions que workflow se ejecutó
# Verificar en Chatwoot que respuesta aparece
```

### 6.4 Verificar Logs

```bash
# Logs Chatwoot (webhook sent)
docker-compose logs chatwoot_web | grep -i webhook | tail -20

# Logs n8n (workflow executed)
docker-compose logs n8n | grep -i "workflow.*executed" | tail -20

# Logs PostgreSQL (queries)
docker-compose logs postgres | tail -50
```

---

## Troubleshooting

### Problema 1: n8n workflow no se ejecuta

**Síntomas:**
- Mensaje enviado en Chatwoot
- No aparece respuesta
- No hay ejecución en n8n Executions tab

**Debug:**

```bash
# 1. Verificar webhook configurado correctamente
docker-compose logs chatwoot_web | grep "webhook.*sent"

# 2. Verificar n8n recibe webhook
docker-compose logs n8n | grep "webhook.*chatwoot-messages"

# 3. Verificar workflow está activo
curl http://localhost:5678/api/v1/workflows | jq '.[] | select(.name=="Message Router") | .active'

# Debe retornar: true
```

**Soluciones:**
- Webhook URL incorrecta → Re-crear webhook con `http://n8n:5678/webhook/chatwoot-messages`
- Workflow inactivo → Activar toggle en n8n UI
- n8n crashed → `docker-compose restart n8n`

---

### Problema 2: OpenAI retorna error 401 (Unauthorized)

**Síntomas:**
- Workflow ejecuta hasta node OpenAI
- Node OpenAI falla con error 401

**Debug:**

```bash
# Verificar API key en n8n credentials
# Settings → Credentials → OpenAI GP Bikes → Edit

# Test API key directamente
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer sk-proj-YOUR-KEY" | jq '.data[0].id'

# Debe retornar: "gpt-4" o similar
```

**Soluciones:**
- API key incorrecta → Re-generar en OpenAI dashboard
- API key expired → Crear nueva key
- Rate limit exceeded → Esperar 1 minuto, reintentar

---

### Problema 3: Chatwoot API retorna 404 (Not Found)

**Síntomas:**
- n8n HTTP Request a Chatwoot falla con 404
- URL: `/api/v1/accounts/1/contacts/456`

**Debug:**

```bash
# Verificar que contact existe
curl -H "api_access_token: $TOKEN" \
  http://localhost:3000/api/v1/accounts/1/contacts | jq '.payload[] | {id, name}'

# Verificar account_id correcto (debe ser 1 en development)
curl -H "api_access_token: $TOKEN" \
  http://localhost:3000/api/v1/accounts | jq '.[] | {id, name}'
```

**Soluciones:**
- Contact ID incorrecto → Usar ID del payload de webhook
- Account ID incorrecto → Actualizar URL a `/api/v1/accounts/1/...`
- API token inválido → Regenerar token en Chatwoot Profile

---

### Problema 4: "Cannot connect to Docker daemon"

**Síntomas:**
```bash
$ docker-compose up
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Soluciones:**
- Docker Desktop no está corriendo → Abrir Docker Desktop
- Permisos insuficientes (Linux) → `sudo usermod -aG docker $USER` + logout/login
- Docker socket corrupted → Restart Docker Desktop

---

### Problema 5: Puerto 3000 ya está en uso

**Síntomas:**
```
Error starting userland proxy: listen tcp 0.0.0.0:3000: bind: address already in use
```

**Debug:**
```bash
# Ver qué proceso usa puerto 3000
lsof -i :3000

# Output ejemplo:
# COMMAND   PID   USER
# ruby      1234  user
```

**Soluciones:**
- **Opción A:** Matar proceso existente
  ```bash
  kill -9 1234
  docker-compose up -d
  ```

- **Opción B:** Cambiar puerto en docker-compose.yml
  ```yaml
  chatwoot:
    ports:
      - "3001:3000"  # Usar puerto 3001 en host
  ```

---

## Próximos Pasos

Una vez completado el setup exitosamente:

1. **Crear workers adicionales:**
   - LeadQualificationWorker
   - ProductCatalogWorker
   - ServiceSchedulingWorker
   - FinancingWorker

2. **Configurar monitoreo:**
   - Ver [`docs/architecture/n8n-architecture.md#da-007-observabilidad`](../architecture/n8n-architecture.md#da-007-observabilidad-uuid-tracking-logs-centralizados)

3. **Implementar testing:**
   - Postman collection E2E
   - Smoke tests post-deploy
   - Ver [`docs/testing/testing-strategy-n8n.md`](../testing/testing-strategy-n8n.md)

4. **Deploy a staging:**
   - Railway setup
   - Ver [`README_ROADMAP.md#fase-5-deployment`](../../README_ROADMAP.md#fase-5-deployment--monitoring-semana-12)

---

## Recursos Adicionales

- **n8n Documentation:** https://docs.n8n.io/
- **Chatwoot API Reference:** https://www.chatwoot.com/developers/api
- **OpenAI API Reference:** https://platform.openai.com/docs/api-reference
- **Docker Compose Reference:** https://docs.docker.com/compose/

---

**Documento preparado por:** Equipo GP Bikes AI
**Última actualización:** 30 de septiembre de 2025
**Versión:** 1.0

Para soporte, contactar a @backend-ai-workers-bolivar o @devops-infrastructure-jorge.
