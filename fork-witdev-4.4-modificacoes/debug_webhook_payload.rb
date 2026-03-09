#!/usr/bin/env ruby

# Simular o payload real que está sendo enviado
real_webhook_payload = {
  "account" => {"id" => 3, "name" => "DraAmandaSousa"},
  "additional_attributes" => {},
  "content_attributes" => {},
  "content_type" => "text",
  "content" => nil,
  "conversation" => {
    "additional_attributes" => {},
    "can_reply" => true,
    "channel" => "Channel::Whatsapp",
    "contact_inbox" => {
      "id" => 1690,
      "contact_id" => 1447,
      "inbox_id" => 4,
      "source_id" => "558597550136"
    },
    "id" => 1778,
    "inbox_id" => 4,
    "meta" => {
      "sender" => {
        "additional_attributes" => {},
        "custom_attributes" => {},
        "email" => nil,
        "id" => 1447,
        "identifier" => nil,
        "name" => "Witalo Rocha",
        "phone_number" => "+558597550136",
        "blocked" => false,
        "type" => "contact"
      }
    },
    "status" => "pending",
    "created_at" => 1753402911,
    "updated_at" => 1753521674.057222
  },
  "created_at" => "2025-07-26T09:21:14.046Z",
  "id" => 32892,
  "inbox" => {
    "id" => 4,
    "name" => "WhatsApp - ANA"
  },
  "message_type" => "incoming",
  "private" => false,
  "sender" => {
    "account" => {"id" => 3, "name" => "DraAmandaSousa"},
    "additional_attributes" => {},
    "custom_attributes" => {},
    "email" => nil,
    "id" => 1447,
    "identifier" => nil,
    "name" => "Witalo Rocha",
    "phone_number" => "+558597550136",
    "blocked" => false
  },
  "source_id" => "wamid.HBgMNTU4NTk3NTUwMTM2FQIAEhgUM0E3REYyMDA4NTVENTkzNzQ3NEYA",
  "event" => "message_created"
}

puts "=== ANÁLISE DO PAYLOAD REAL ==="
puts "Chaves principais: #{real_webhook_payload.keys}"
puts ""
puts "Dados da mensagem:"
puts "- ID: #{real_webhook_payload['id']}"
puts "- Content: #{real_webhook_payload['content'].inspect}"
puts "- Source ID: #{real_webhook_payload['source_id']}"
puts "- Content Attributes: #{real_webhook_payload['content_attributes']}"
puts ""
puts "Dados da conversa:"
puts "- ID: #{real_webhook_payload['conversation']['id']}"
puts "- Status: #{real_webhook_payload['conversation']['status']}"
puts "- Channel: #{real_webhook_payload['conversation']['channel']}"
puts ""
puts "Dados do contato (via sender):"
puts "- ID: #{real_webhook_payload['sender']['id']}"
puts "- Nome: #{real_webhook_payload['sender']['name']}"
puts "- Telefone: #{real_webhook_payload['sender']['phone_number']}"
puts ""
puts "Dados do contato (via conversation.meta.sender):"
puts "- ID: #{real_webhook_payload['conversation']['meta']['sender']['id']}"
puts "- Nome: #{real_webhook_payload['conversation']['meta']['sender']['name']}"
puts "- Telefone: #{real_webhook_payload['conversation']['meta']['sender']['phone_number']}"
puts ""
puts "Dados da inbox:"
puts "- ID: #{real_webhook_payload['inbox']['id']}"
puts "- Nome: #{real_webhook_payload['inbox']['name']}"
puts ""
puts "=== ESTRUTURA PARA EXTRAÇÃO ==="
puts "Message: Dados estão no nível raiz do payload"
puts "Conversation: payload['conversation']"
puts "Contact: payload['sender'] OU payload['conversation']['meta']['sender']"
puts "Inbox: payload['inbox'] (mas sem channel info)"