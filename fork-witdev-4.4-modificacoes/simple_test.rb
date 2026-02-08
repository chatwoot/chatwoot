#!/usr/bin/env ruby

# Teste simples da lógica de extração
require 'ostruct'

# Simular o payload real
real_webhook_payload = {
  "account" => {"id" => 3, "name" => "DraAmandaSousa"},
  "content_attributes" => {},
  "content_type" => "text",
  "content" => nil,
  "conversation" => {
    "channel" => "Channel::Whatsapp",
    "id" => 1778,
    "inbox_id" => 4,
    "status" => "pending",
    "created_at" => 1753402911,
    "updated_at" => 1753521674.057222,
    "meta" => {
      "sender" => {
        "id" => 1447,
        "name" => "Witalo Rocha",
        "phone_number" => "+558597550136",
        "email" => nil,
        "custom_attributes" => {}
      }
    }
  },
  "id" => 32892,
  "inbox" => {"id" => 4, "name" => "WhatsApp - ANA"},
  "message_type" => "incoming",
  "sender" => {
    "id" => 1447,
    "name" => "Witalo Rocha",
    "phone_number" => "+558597550136",
    "custom_attributes" => {}
  },
  "source_id" => "wamid.HBgMNTU4NTk3NTUwMTM2FQIAEhgUM0E3REYyMDA4NTVENTkzNzQ3NEYA",
  "event" => "message_created"
}

puts "=== ANÁLISE DA ESTRUTURA DO PAYLOAD ==="
puts "Payload tem as chaves: #{real_webhook_payload.keys}"
puts ""

# Testar detecção de mensagem
puts "=== DETECÇÃO DE MENSAGEM ==="
if real_webhook_payload.key?('id') && real_webhook_payload.key?('content') && real_webhook_payload.key?('message_type')
  puts "✅ Payload é uma mensagem (dados no nível raiz)"
  puts "- ID: #{real_webhook_payload['id']}"
  puts "- Content: #{real_webhook_payload['content'].inspect}"
  puts "- Message Type: #{real_webhook_payload['message_type']}"
  puts "- Source ID: #{real_webhook_payload['source_id']}"
else
  puts "❌ Payload NÃO é uma mensagem"
end

puts ""
puts "=== EXTRAÇÃO DE CONTATO ==="
# Testar extração de contato
contact = real_webhook_payload['sender']
if contact
  puts "✅ Contato encontrado via 'sender'"
  puts "- ID: #{contact['id']}"
  puts "- Nome: #{contact['name']}"
  puts "- Telefone: #{contact['phone_number']}"
else
  puts "❌ Contato NÃO encontrado via 'sender'"
end

# Testar via conversation.meta.sender
contact_alt = real_webhook_payload.dig('conversation', 'meta', 'sender')
if contact_alt
  puts "✅ Contato alternativo encontrado via 'conversation.meta.sender'"
  puts "- ID: #{contact_alt['id']}"
  puts "- Nome: #{contact_alt['name']}"
  puts "- Telefone: #{contact_alt['phone_number']}"
else
  puts "❌ Contato alternativo NÃO encontrado"
end

puts ""
puts "=== EXTRAÇÃO DE CONVERSA ==="
conversation = real_webhook_payload['conversation']
if conversation
  puts "✅ Conversa encontrada"
  puts "- ID: #{conversation['id']}"
  puts "- Status: #{conversation['status']}"
  puts "- Channel: #{conversation['channel']}"
else
  puts "❌ Conversa NÃO encontrada"
end

puts ""
puts "=== EXTRAÇÃO DE INBOX ==="
inbox = real_webhook_payload['inbox']
if inbox
  puts "✅ Inbox encontrada"
  puts "- ID: #{inbox['id']}"
  puts "- Nome: #{inbox['name']}"
  puts "- Tem channel_type? #{inbox.key?('channel_type')}"
  puts "- Channel type via conversation: #{conversation['channel'] if conversation}"
else
  puts "❌ Inbox NÃO encontrada"
end

puts ""
puts "=== CONCLUSÃO ==="
puts "✅ Estrutura do webhook está clara"
puts "✅ Dados podem ser extraídos corretamente"
puts "⚠️  Inbox precisa buscar provider_config do banco de dados"