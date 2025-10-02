# 🔧 Solución Rápida: Actualizar Token de Webhook en Producción

**Problema:** Webhook configurado en Meta pero mensajes no llegan a Chatwoot

**Causa:** Token en DB no coincide con token en Meta

---

## ⚡ Solución Rápida (5 minutos)

### **Paso 1: Conectar a Render Shell**

1. Ve a: https://dashboard.render.com
2. Selecciona tu servicio: `crm-agents`
3. Click en pestaña **"Shell"**
4. Espera a que cargue el terminal

### **Paso 2: Ejecutar Script de Actualización**

Copia y pega este comando completo:

```bash
rails runner scripts/update_webhook_token_production.rb
```

**Salida esperada:**
```
🔧 ACTUALIZANDO WEBHOOK TOKEN EN PRODUCCIÓN
======================================================================

📱 Canal encontrado:
   ID: 1
   Phone: +573044993499
   Provider: whatsapp_cloud

🔑 Tokens:
   Actual (DB):  8ba146649dea162425c9cb29b933c1b0
   Nuevo (Meta): f1d1c57e2645b6edc7eb102df295414b

🔄 Actualizando token...
✅ Token actualizado exitosamente

📋 Verificación:
   ✓ Token verificado en DB: f1d1c57e2645b6edc7eb102df295414b

🎯 Próximos pasos:
   1. El webhook ya está configurado en Meta
   2. Envía un mensaje de prueba al +573044993499
   3. Verifica que aparezca en Chatwoot inbox
   4. Monitorea los logs buscando [WHATSAPP_WEBHOOK]

======================================================================
✅ ACTUALIZACIÓN COMPLETADA
======================================================================
```

### **Paso 3: Probar el Webhook**

1. **Envía mensaje de WhatsApp** a `+573044993499`
2. **Ve a Render Logs** (pestaña "Logs" en Render)
3. **Busca logs** que contengan `[WHATSAPP_WEBHOOK]`

**Deberías ver:**
```
[WHATSAPP_WEBHOOK] Message payload received for: +573044993499
[WHATSAPP_WEBHOOK] Message queued for processing
```

4. **Ve a Chatwoot** → Inbox "GP Bikes"
5. **Verifica** que aparezca la conversación

---

## 🔍 Verificación Manual (Alternativa)

Si prefieres hacerlo paso a paso en Render Shell:

```bash
# 1. Verificar token actual
rails runner "
channel = Channel::Whatsapp.find_by(phone_number: '+573044993499')
puts 'Token actual: ' + channel.provider_config['webhook_verify_token']
"

# 2. Actualizar token
rails runner "
channel = Channel::Whatsapp.find_by(phone_number: '+573044993499')
channel.provider_config['webhook_verify_token'] = 'f1d1c57e2645b6edc7eb102df295414b'
channel.save!
puts '✅ Token actualizado'
"

# 3. Verificar que se guardó
rails runner "
channel = Channel::Whatsapp.find_by(phone_number: '+573044993499')
puts 'Token nuevo: ' + channel.provider_config['webhook_verify_token']
"
```

---

## 📊 Resumen Técnico

### **¿Por qué falló?**

1. **Webhook verification (GET)** funcionó porque casualmente el token coincidía temporalmente
2. **Message delivery (POST)** falla porque:
   - Meta envía mensajes a: `/webhooks/whatsapp/+573044993499`
   - El controller busca el canal: `Channel::Whatsapp.find_by(phone_number: '+573044993499')`
   - Lee token de DB: `8ba146649dea162425c9cb29b933c1b0`
   - Pero Meta espera: `f1d1c57e2645b6edc7eb102df295414b`
   - **No coinciden** → responde 401 Unauthorized
   - Meta interpreta esto como error y NO procesa el mensaje

### **¿Qué hace el fix?**

Actualiza `channel.provider_config['webhook_verify_token']` de:
- ❌ `8ba146649dea162425c9cb29b933c1b0` (incorrecto)
- ✅ `f1d1c57e2645b6edc7eb102df295414b` (correcto, coincide con Meta)

### **Flujo después del fix:**

```
1. Usuario envía WhatsApp → +573044993499
2. Meta recibe mensaje
3. Meta envía POST a tu webhook con token f1d1c57e2645b6edc7eb102df295414b
4. Controller busca canal por phone_number
5. Lee token de DB: f1d1c57e2645b6edc7eb102df295414b ✅
6. Tokens coinciden → acepta el request
7. Encola job: Webhooks::WhatsappEventsJob
8. Job procesa mensaje → crea Conversation en Chatwoot
9. ✅ Mensaje aparece en inbox
```

---

## 🆘 Si Sigue Sin Funcionar

**Posibles causas adicionales:**

### 1. **FRONTEND_URL incorrecto**
```bash
# Verificar en Render Shell
rails runner "puts ENV['FRONTEND_URL']"

# Debe mostrar:
# https://crm-agents.onrender.com
```

### 2. **Canal inactivo**
```bash
# Verificar en Render Shell
rails runner "
channel = Channel::Whatsapp.find_by(phone_number: '+573044993499')
puts 'Account active: ' + channel.account.active?.to_s
puts 'Channel reauth needed: ' + channel.reauthorization_required?.to_s
"

# Debe mostrar:
# Account active: true
# Channel reauth needed: false
```

### 3. **Phone number ID incorrecto**
```bash
# Verificar en Render Shell
rails runner "
channel = Channel::Whatsapp.find_by(phone_number: '+573044993499')
puts 'Phone Number ID: ' + channel.provider_config['phone_number_id']
"

# Debe coincidir con el de Meta Developer Console
```

### 4. **Webhook URL en Meta incorrecto**

Verifica en Meta Developer Console:
- URL: `https://crm-agents.onrender.com/webhooks/whatsapp/+573044993499`
- Token: `f1d1c57e2645b6edc7eb102df295414b`
- Fields subscribed: `messages`, `message_status`

---

## 📝 Logs Útiles

**En Render → Logs, buscar:**

### **Logs exitosos (webhook funcionando):**
```
[WHATSAPP_WEBHOOK] Message payload received for: +573044993499
[WHATSAPP_WEBHOOK] Message queued for processing
Processing by Webhooks::WhatsappEventsJob
```

### **Logs de error (token incorrecto):**
```
[WHATSAPP_WEBHOOK] ❌ Token validation FAILED - tokens don't match
Started POST "/webhooks/whatsapp/+573044993499" for ...
Completed 401 Unauthorized in ...
```

### **Logs de error (canal no encontrado):**
```
[WHATSAPP_WEBHOOK] No channel found for phone: +573044993499
Completed 401 Unauthorized in ...
```

---

## ✅ Checklist Final

- [ ] Script ejecutado en Render Shell exitosamente
- [ ] Token actualizado verificado: `f1d1c57e2645b6edc7eb102df295414b`
- [ ] Mensaje de prueba enviado al +573044993499
- [ ] Logs muestran `[WHATSAPP_WEBHOOK] Message payload received`
- [ ] Conversación aparece en Chatwoot inbox "GP Bikes"
- [ ] Respuesta automática funciona (si AI Workers habilitados)

---

**Última actualización:** 2 de Octubre 2025
**Tiempo estimado:** 5 minutos
**Dificultad:** ⭐☆☆☆☆ (Muy fácil)
