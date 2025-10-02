#!/usr/bin/env ruby
# Script para actualizar el webhook_verify_token en producción
# Ejecutar en Render Shell: rails runner scripts/update_webhook_token_production.rb

puts '🔧 ACTUALIZANDO WEBHOOK TOKEN EN PRODUCCIÓN'
puts '=' * 70
puts ''

# Configuración
PHONE_NUMBER = '+573044993499'
NEW_TOKEN = 'f1d1c57e2645b6edc7eb102df295414b'

# Buscar canal
channel = Channel::Whatsapp.find_by(phone_number: PHONE_NUMBER)

if channel.nil?
  puts "❌ ERROR: No se encontró canal para #{PHONE_NUMBER}"
  exit 1
end

# Mostrar estado actual
old_token = channel.provider_config['webhook_verify_token']

puts '📱 Canal encontrado:'
puts "   ID: #{channel.id}"
puts "   Phone: #{channel.phone_number}"
puts "   Provider: #{channel.provider}"
puts ''

puts '🔑 Tokens:'
puts "   Actual (DB):  #{old_token || 'NOT SET'}"
puts "   Nuevo (Meta): #{NEW_TOKEN}"
puts ''

# Verificar si necesita actualización
if old_token == NEW_TOKEN
  puts '✅ El token ya es correcto. No se necesita actualizar.'
  exit 0
end

# Actualizar token
puts '🔄 Actualizando token...'
channel.provider_config['webhook_verify_token'] = NEW_TOKEN

if channel.save
  puts '✅ Token actualizado exitosamente'
  puts ''
  puts '📋 Verificación:'

  # Recargar desde DB para confirmar
  channel.reload
  current_token = channel.provider_config['webhook_verify_token']

  if current_token == NEW_TOKEN
    puts "   ✓ Token verificado en DB: #{current_token}"
    puts ''
    puts '🎯 Próximos pasos:'
    puts '   1. El webhook ya está configurado en Meta'
    puts '   2. Envía un mensaje de prueba al +573044993499'
    puts '   3. Verifica que aparezca en Chatwoot inbox'
    puts '   4. Monitorea los logs buscando [WHATSAPP_WEBHOOK]'
  else
    puts '   ❌ ERROR: El token no se guardó correctamente'
    puts "   Esperado: #{NEW_TOKEN}"
    puts "   Obtenido: #{current_token}"
  end
else
  puts "❌ ERROR al guardar: #{channel.errors.full_messages.join(', ')}"
  exit 1
end

puts ''
puts '=' * 70
puts '✅ ACTUALIZACIÓN COMPLETADA'
puts '=' * 70
