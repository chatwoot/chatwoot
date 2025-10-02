# 🛠️ Herramientas de Troubleshooting

Este directorio contiene herramientas y guías para diagnosticar y resolver problemas comunes.

## 📁 Contenido

### 1. [whatsapp-webhook-setup.md](./whatsapp-webhook-setup.md)
**Guía completa de configuración y troubleshooting de webhooks de WhatsApp**

- 📖 Explicación de cómo funcionan los webhooks
- ⚙️ Pasos de configuración inicial
- 🚨 Problemas comunes y soluciones
- ✅ Checklist de producción

**Cuándo usar**: Cuando tengas problemas configurando el webhook en Meta Developer Console.

---

## 🔧 Herramientas Disponibles

### 1. Rake Task: Debug WhatsApp Webhook

**Ubicación**: `lib/tasks/whatsapp_webhook_debug.rake`

**Comandos disponibles**:

```bash
# 1. Diagnóstico completo (RECOMENDADO)
bundle exec rake whatsapp:webhook:debug

# 2. Ver configuración actual
bundle exec rake whatsapp:webhook:show_config

# 3. Test de endpoint
bundle exec rake whatsapp:webhook:test_endpoint['+573017668760','tu_token']

# 4. Actualizar token de verificación
bundle exec rake whatsapp:webhook:update_token['+573017668760']
```

**Output de ejemplo**:
```
🔍 WHATSAPP WEBHOOK DEBUG TOOL
============================================================

📋 Step 1: Checking WhatsApp Channels in Database
✅ Found 1 WhatsApp channel(s):

1. Channel Details:
   Phone Number: +573044993499
   Provider: whatsapp_cloud
   Account ID: 1

   Provider Config:
   - webhook_verify_token: 8ba146649dea162425c9cb29b933c1b0
   - phone_number_id: ✅ SET
   - business_account_id: ✅ SET

📡 Step 2: Testing Webhook Verification Endpoint
✅ Token validation: PASSED

📊 DIAGNOSTIC SUMMARY
✅ All checks passed! Webhook should work correctly.
```

---

### 2. Script Bash: Test Webhook

**Ubicación**: `scripts/test_whatsapp_webhook.sh`

**Uso**:
```bash
# Sintaxis básica
./scripts/test_whatsapp_webhook.sh <phone_number> <verify_token> [base_url]

# Ejemplo desarrollo local
./scripts/test_whatsapp_webhook.sh +573044993499 8ba146649dea162425c9cb29b933c1b0 http://localhost:3000

# Ejemplo producción
./scripts/test_whatsapp_webhook.sh +573044993499 8ba146649dea162425c9cb29b933c1b0 https://chatwoot-gpbikes-production.onrender.com
```

**Qué hace**:
1. ✅ Verifica conectividad al servidor
2. ✅ Prueba el endpoint de verificación GET
3. ✅ Valida la respuesta (status code y body)
4. ✅ Verifica headers
5. ✅ Proporciona instrucciones para Meta

**Output de ejemplo**:
```
🧪 WhatsApp Webhook Tester
============================================================

Test 1: Verificar Conectividad Básica
✅ Servidor accesible

Test 2: Probar Endpoint de Verificación
📨 Respuesta del servidor:
  Status Code: 200
  Response Body: test_challenge_12345

Test 3: Validar Respuesta
✅ Status code: 200 OK
✅ Response body correcto: retornó el hub.challenge

📊 Resumen
✅ Webhook endpoint está funcionando correctamente

🎯 Próximos pasos:
   [Instrucciones para configurar en Meta...]
```

---

## 🚀 Flujo de Trabajo Recomendado

### Si el webhook NO está funcionando:

**Paso 1**: Ejecutar diagnóstico completo
```bash
bundle exec rake whatsapp:webhook:debug
```

**Paso 2**: Revisar problemas reportados y seguir soluciones sugeridas

**Paso 3**: Si el diagnóstico pasa, probar manualmente con el script bash
```bash
./scripts/test_whatsapp_webhook.sh +573044993499 [tu_token]
```

**Paso 4**: Si todo funciona localmente pero Meta rechaza, revisar:
- [ ] URL es accesible públicamente (no localhost)
- [ ] URL usa HTTPS (requerido en producción)
- [ ] Token copiado correctamente (sin espacios extra)
- [ ] Número de teléfono correcto en la URL

**Paso 5**: Ver logs en tiempo real mientras configuras en Meta
```bash
# Desarrollo
tail -f log/development.log | grep -i whatsapp

# Producción (Render)
# https://dashboard.render.com/web/[tu-servicio]/logs
```

---

## 📝 Logs Mejorados

El `WhatsappController` ahora incluye logs detallados:

```ruby
[WHATSAPP_WEBHOOK] Verification request received
[WHATSAPP_WEBHOOK] Phone: +573044993499
[WHATSAPP_WEBHOOK] Hub mode: subscribe
[WHATSAPP_WEBHOOK] Validating token for phone: +573044993499
[WHATSAPP_WEBHOOK] Channel found: ID=1, Provider=whatsapp_cloud
[WHATSAPP_WEBHOOK] ✅ Token validation SUCCESS
```

Estos logs aparecerán automáticamente en:
- `log/development.log` (local)
- `log/production.log` (producción)
- Dashboard de Render → Logs (producción en la nube)

---

## 🔍 Casos de Uso

### Caso 1: "Meta rechaza mi webhook con error de token"

**Solución**:
1. Verificar token en DB:
   ```bash
   bundle exec rake whatsapp:webhook:show_config
   ```
2. Copiar token EXACTAMENTE a Meta (sin espacios)
3. Si no funciona, generar nuevo token:
   ```bash
   bundle exec rake whatsapp:webhook:update_token['+573044993499']
   ```

### Caso 2: "El endpoint devuelve 404"

**Solución**:
1. Verificar que el canal existe:
   ```bash
   rails c
   Channel::Whatsapp.find_by(phone_number: '+573044993499')
   ```
2. Si no existe, crear canal en Chatwoot UI
3. Verificar rutas:
   ```bash
   rails routes | grep whatsapp
   ```

### Caso 3: "Funciona en local pero no en producción"

**Solución**:
1. Verificar variable `FRONTEND_URL`:
   ```bash
   # En producción
   rails c
   puts ENV['FRONTEND_URL']
   # Debe ser: https://tu-dominio.com (con HTTPS)
   ```
2. Verificar que la app esté corriendo en Render
3. Test el endpoint público:
   ```bash
   ./scripts/test_whatsapp_webhook.sh +573044993499 [token] https://tu-dominio.com
   ```

---

## 📚 Recursos Adicionales

- [Guía completa de WhatsApp Webhook](./whatsapp-webhook-setup.md)
- [Documentación Meta WhatsApp API](https://developers.facebook.com/docs/whatsapp/cloud-api/webhooks)
- [Documentación Chatwoot](https://www.chatwoot.com/docs/product/channels/whatsapp/)

---

## 🆘 Soporte

Si ninguna de estas herramientas resuelve tu problema:

1. Ejecutar **TODOS** los diagnósticos y guardar outputs
2. Capturar screenshot del error en Meta
3. Exportar últimos 100 logs: `tail -100 log/production.log > debug.log`
4. Reportar issue con toda la información recopilada

---

**Última actualización**: Octubre 2025
