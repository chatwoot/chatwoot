#!/usr/bin/env ruby

# Debug script para investigar por que mensagens ricas do Instagram não aparecem no SocialWise Flow

puts "=== DEBUG: Instagram Rich Messages no SocialWise Flow ==="

# Simular payload do SocialWise Flow (baseado no design.md)
socialwise_instagram_payload = {
  "instagram" => {
    "message_format" => "GENERIC_TEMPLATE",
    "template_type" => "generic",
    "elements" => [
      {
        "title" => "mandado de segurança\n\nDra. Amanda Sousa Advocacia e Consultoria Jurídica™",
        "buttons" => [
          {
            "type" => "postback",
            "title" => "atendimento",
            "payload" => "ig_btn_1756139332989_pm6hd9wau"
          }
        ],
        "image_url" => "https://objstoreapi.witdev.com.br/chatwit-social/1b2024eb-ecd3-486d-8629-57a1df029b08.png"
      }
    ]
  }
}

puts "\n1. Payload recebido pelo SocialWise Flow:"
puts socialwise_instagram_payload.inspect

puts "\n2. Extraindo payload do Instagram:"
instagram_payload = socialwise_instagram_payload["instagram"]
puts instagram_payload.inspect

puts "\n3. Verificando estrutura do payload:"
puts "   message_format: #{instagram_payload['message_format']}"
puts "   template_type: #{instagram_payload['template_type']}"
puts "   elements count: #{instagram_payload['elements']&.length}"

puts "\n4. Comparando com estrutura esperada pelo InstagramResponseProcessor:"
puts "   ✓ message_format presente: #{instagram_payload['message_format'].present?}"
puts "   ✓ payload (elements) presente: #{instagram_payload['elements'].present?}"

puts "\n5. Testando validação do InstagramResponseProcessor:"

# Simular o que acontece no process_instagram_response
begin
  # Verificar se é canal Instagram (FacebookPage) - isso seria feito no código real
  puts "   ✓ Canal seria validado como Channel::FacebookPage"
  
  # Chamar o InstagramResponseProcessor.process (simulado)
  puts "   ✓ Chamaria Integrations::Socialwise::InstagramResponseProcessor.process"
  puts "     - Primeiro parâmetro: instagram_payload (#{instagram_payload.class})"
  puts "     - Segundo parâmetro: message object"
  
  # Verificar se a estrutura está correta para o processor
  message_format = instagram_payload['message_format']
  payload = instagram_payload
  
  puts "\n6. Estrutura interna do processor:"
  puts "   message_format: #{message_format}"
  puts "   payload keys: #{payload.keys.inspect}"
  
  # O problema pode estar aqui - o processor espera 'payload' mas recebe o payload direto
  puts "\n7. POSSÍVEL PROBLEMA IDENTIFICADO:"
  puts "   O InstagramResponseProcessor.process espera:"
  puts "   - socialwise_data['message_format']"
  puts "   - socialwise_data['payload']"
  puts "   "
  puts "   Mas o SocialWise Flow está enviando:"
  puts "   - instagram_payload['message_format']"
  puts "   - instagram_payload (sem chave 'payload')"
  
  puts "\n8. Estrutura correta deveria ser:"
  correct_structure = {
    'message_format' => instagram_payload['message_format'],
    'payload' => {
      'template_type' => instagram_payload['template_type'],
      'elements' => instagram_payload['elements']
    }
  }
  puts correct_structure.inspect
  
rescue => e
  puts "   ❌ ERRO: #{e.message}"
end

puts "\n=== DIAGNÓSTICO ==="
puts "🔍 PROBLEMA IDENTIFICADO:"
puts "   O SocialWise Flow está enviando o payload do Instagram em formato diferente"
puts "   do que o InstagramResponseProcessor espera."
puts ""
puts "📋 ESTRUTURA ATUAL (SocialWise Flow):"
puts "   instagram: {"
puts "     message_format: 'GENERIC_TEMPLATE',"
puts "     template_type: 'generic',"
puts "     elements: [...]"
puts "   }"
puts ""
puts "📋 ESTRUTURA ESPERADA (InstagramResponseProcessor):"
puts "   {"
puts "     message_format: 'GENERIC_TEMPLATE',"
puts "     payload: {"
puts "       template_type: 'generic',"
puts "       elements: [...]"
puts "     }"
puts "   }"
puts ""
puts "🔧 SOLUÇÃO:"
puts "   Modificar o process_instagram_response no SocialwiseFlowProcessorService"
puts "   para reestruturar o payload antes de chamar o InstagramResponseProcessor"