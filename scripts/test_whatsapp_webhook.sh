#!/bin/bash

# ==============================================================================
# WhatsApp Webhook Test Script
# ==============================================================================
# Prueba el endpoint de verificación de webhook de WhatsApp
# Simula la petición GET que Meta/Facebook hace durante la configuración
#
# Uso:
#   ./scripts/test_whatsapp_webhook.sh [phone_number] [verify_token] [base_url]
#
# Ejemplos:
#   ./scripts/test_whatsapp_webhook.sh +573017668760 28f08d2be4f3ada8f9cc57e4310487d8
#   ./scripts/test_whatsapp_webhook.sh +573017668760 28f08d2be4f3ada8f9cc57e4310487d8 https://chatwoot-gpbikes-production.onrender.com
# ==============================================================================

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# Funciones Helper
# ==============================================================================

print_header() {
    echo -e "\n${BLUE}============================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ==============================================================================
# Parámetros
# ==============================================================================

PHONE_NUMBER="${1}"
VERIFY_TOKEN="${2}"
BASE_URL="${3:-https://chatwoot-gpbikes-production.onrender.com}"

# ==============================================================================
# Validación de parámetros
# ==============================================================================

print_header "🧪 WhatsApp Webhook Tester"

if [ -z "$PHONE_NUMBER" ] || [ -z "$VERIFY_TOKEN" ]; then
    print_error "Faltan parámetros requeridos"
    echo ""
    echo "Uso:"
    echo "  $0 <phone_number> <verify_token> [base_url]"
    echo ""
    echo "Ejemplos:"
    echo "  $0 +573017668760 28f08d2be4f3ada8f9cc57e4310487d8"
    echo "  $0 +573017668760 mytoken https://mi-servidor.com"
    echo ""
    echo "Parámetros:"
    echo "  phone_number  - Número de teléfono WhatsApp (ej: +573017668760)"
    echo "  verify_token  - Token de verificación del canal"
    echo "  base_url      - URL base del servidor (default: https://chatwoot-gpbikes-production.onrender.com)"
    echo ""
    exit 1
fi

# ==============================================================================
# Configuración
# ==============================================================================

# URL encode del número de teléfono
ENCODED_PHONE=$(printf %s "$PHONE_NUMBER" | jq -sRr @uri 2>/dev/null || python3 -c "import urllib.parse; print(urllib.parse.quote('$PHONE_NUMBER'))" 2>/dev/null || echo "$PHONE_NUMBER")

# Construir URL completa
CALLBACK_URL="${BASE_URL}/webhooks/whatsapp/${ENCODED_PHONE}"

# Parámetros de verificación (simulan lo que Meta envía)
HUB_MODE="subscribe"
HUB_CHALLENGE="test_challenge_12345"
VERIFY_URL="${CALLBACK_URL}?hub.mode=${HUB_MODE}&hub.challenge=${HUB_CHALLENGE}&hub.verify_token=${VERIFY_TOKEN}"

# ==============================================================================
# Mostrar información
# ==============================================================================

print_info "Configuración:"
echo "  📱 Phone Number: $PHONE_NUMBER"
echo "  🔑 Verify Token: ${VERIFY_TOKEN:0:10}...${VERIFY_TOKEN: -4}"  # Muestra solo inicio y fin
echo "  🌐 Base URL: $BASE_URL"
echo ""
echo "  📍 Callback URL:"
echo "     $CALLBACK_URL"
echo ""

# ==============================================================================
# Test 1: Verificar conectividad básica
# ==============================================================================

print_header "Test 1: Verificar Conectividad Básica"

print_info "Probando conexión a: $BASE_URL"

if curl -s -f -o /dev/null --max-time 10 "$BASE_URL" 2>/dev/null; then
    print_success "Servidor accesible"
else
    print_error "No se puede conectar al servidor"
    print_warning "Verifica que el servidor esté corriendo y sea accesible públicamente"
    exit 1
fi

# ==============================================================================
# Test 2: Probar endpoint de verificación
# ==============================================================================

print_header "Test 2: Probar Endpoint de Verificación"

print_info "Enviando GET request a endpoint de webhook..."
echo "  URL: $VERIFY_URL"
echo ""

# Hacer request con curl y capturar respuesta
HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" "$VERIFY_URL" 2>/dev/null)

# Separar body y status code
HTTP_BODY=$(echo "$HTTP_RESPONSE" | head -n -1)
HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -n 1)

echo "📨 Respuesta del servidor:"
echo "  Status Code: $HTTP_STATUS"
echo "  Response Body: $HTTP_BODY"
echo ""

# ==============================================================================
# Test 3: Validar respuesta
# ==============================================================================

print_header "Test 3: Validar Respuesta"

# Verificar status code
if [ "$HTTP_STATUS" = "200" ]; then
    print_success "Status code: 200 OK"
else
    print_error "Status code incorrecto: $HTTP_STATUS (esperado: 200)"

    if [ "$HTTP_STATUS" = "401" ]; then
        print_error "Token de verificación inválido o no coincide"
        echo ""
        echo "💡 Soluciones:"
        echo "   1. Verifica que el token sea correcto:"
        echo "      rails c"
        echo "      Channel::Whatsapp.find_by(phone_number: '$PHONE_NUMBER').provider_config['webhook_verify_token']"
        echo ""
        echo "   2. Actualiza el token si es necesario:"
        echo "      bundle exec rake whatsapp:webhook:update_token['$PHONE_NUMBER']"
    elif [ "$HTTP_STATUS" = "404" ]; then
        print_error "Endpoint no encontrado"
        echo ""
        echo "💡 Soluciones:"
        echo "   1. Verifica que el canal WhatsApp exista en la base de datos:"
        echo "      rails c"
        echo "      Channel::Whatsapp.find_by(phone_number: '$PHONE_NUMBER')"
        echo ""
        echo "   2. Verifica las rutas:"
        echo "      rails routes | grep whatsapp"
    elif [ "$HTTP_STATUS" = "500" ]; then
        print_error "Error interno del servidor"
        echo ""
        echo "💡 Revisa los logs del servidor:"
        echo "   tail -f log/production.log | grep -i whatsapp"
    fi

    exit 1
fi

# Verificar que el body sea el challenge
if [ "$HTTP_BODY" = "\"$HUB_CHALLENGE\"" ] || [ "$HTTP_BODY" = "$HUB_CHALLENGE" ]; then
    print_success "Response body correcto: retornó el hub.challenge"
else
    print_warning "Response body inesperado"
    echo "  Esperado: $HUB_CHALLENGE"
    echo "  Recibido: $HTTP_BODY"
fi

# ==============================================================================
# Test 4: Verificar headers (opcional)
# ==============================================================================

print_header "Test 4: Verificar Headers"

print_info "Obteniendo headers de respuesta..."

HEADERS=$(curl -s -I "$VERIFY_URL" 2>/dev/null | tr -d '\r')

echo "$HEADERS" | grep -i "content-type" && print_success "Content-Type header presente" || print_warning "Content-Type header no encontrado"
echo "$HEADERS" | grep -i "x-request-id" && print_info "X-Request-Id: $(echo "$HEADERS" | grep -i "x-request-id" | cut -d: -f2 | xargs)"

# ==============================================================================
# Resumen Final
# ==============================================================================

print_header "📊 Resumen"

print_success "Webhook endpoint está funcionando correctamente"
echo ""
echo "🎯 Próximos pasos:"
echo ""
echo "1. Copia esta información a Meta Developer Console:"
echo ""
echo "   📍 Callback URL:"
echo "      $CALLBACK_URL"
echo ""
echo "   🔑 Verify Token:"
echo "      $VERIFY_TOKEN"
echo ""
echo "2. En Meta Developer Console:"
echo "   - Ve a: https://developers.facebook.com/apps"
echo "   - Selecciona tu app → WhatsApp → Configuration"
echo "   - En 'Webhook', haz clic en 'Edit'"
echo "   - Pega la Callback URL y el Verify Token"
echo "   - Haz clic en 'Verify and Save'"
echo ""
echo "3. Subscríbete a los siguientes campos webhook:"
echo "   ✓ messages"
echo "   ✓ message_status (opcional)"
echo ""
echo "4. Envía un mensaje de prueba al número WhatsApp para verificar"
echo ""

print_success "¡Configuración completada! 🎉"
