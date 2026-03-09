#!/usr/bin/env ruby

# Script para debugar por que o Socialwise não está funcionando
require_relative 'config/environment'

puts "=== DEBUG SOCIALWISE - ANÁLISE DE LOGS ==="
puts ""

# Analisar o payload do webhook recebido
webhook_payload = {
  "object" => "whatsapp_business_account",
  "entry" => [{
    "id" => "294585820394901",
    "changes" => [{
      "value" => {
        "messaging_product" => "whatsapp",
        "metadata" => {
          "display_phone_number" => "558592091821",
          "phone_number_id" => "274633962398273"
        },
        "contacts" => [{
          "profile" => {"name" => "Witalo Rocha"},
          "wa_id" => "558597550136"
        }],
        "messages" => [{
          "from" => "558597550136",
          "id" => "wamid.HBgMNTU4NTk3NTUwMTM2FQIAEhgUM0FCODMwRTE2NzZENjUxQTM2QjAA",
          "timestamp" => "1753525182",
          "type" => "image",
          "image" => {
            "mime_type" => "image/jpeg",
            "sha256" => "ajL+w8ed7+9yhY3RcfEmMMfXUc/+KUftYvwtOoNE6Bw=",
            "id" => "1144390070832151"
          }
        }]
      },
      "field" => "messages"
    }]
  }],
  "phone_number" => "+558592091821"
}

puts "1. ANÁLISE DO WEBHOOK RECEBIDO:"
puts "- Tipo: #{webhook_payload['object']}"
puts "- Phone Number: #{webhook_payload['phone_number']}"
puts "- Phone Number ID: #{webhook_payload.dig('entry', 0, 'changes', 0, 'value', 'metadata', 'phone_number_id')}"
puts "- Contact: #{webhook_payload.dig('entry', 0, 'changes', 0, 'value', 'contacts', 0, 'profile', 'name')}"
puts "- Message Type: #{webhook_payload.dig('entry', 0, 'changes', 0, 'value', 'messages', 0, 'type')}"
puts ""

# Verificar se existe inbox com esse número
phone_number = webhook_payload['phone_number']
puts "2. VERIFICAÇÃO DE INBOX:"

inbox = Inbox.joins(:channel).where(
  channel_type: 'Channel::Whatsapp',
  channels: { phone_number: phone_number }
).first

if inbox
  puts "✅ Inbox encontrada:"
  puts "- ID: #{inbox.id}"
  puts "- Nome: #{inbox.name}"
  puts "- Account ID: #{inbox.account_id}"
  puts "- Channel Type: #{inbox.channel_type}"
  
  # Verificar provider_config
  if inbox.channel.provider_config.present?
    puts "- Provider Config: Presente"
    puts "- API Key: #{inbox.channel.provider_config['api_key'].present? ? 'Presente' : 'Ausente'}"
    puts "- Phone Number ID: #{inbox.channel.provider_config['phone_number_id'] || 'Ausente'}"
    puts "- Business Account ID: #{inbox.channel.provider_config['business_account_id'] || 'Ausente'}"
  else
    puts "- Provider Config: AUSENTE"
  end
else
  puts "❌ Inbox NÃO encontrada para o número #{phone_number}"
  
  # Listar todas as inboxes WhatsApp
  whatsapp_inboxes = Inbox.joins(:channel).where(channel_type: 'Channel::Whatsapp')
  puts ""
  puts "Inboxes WhatsApp disponíveis:"
  whatsapp_inboxes.each do |wb_inbox|
    puts "- ID: #{wb_inbox.id}, Nome: #{wb_inbox.name}, Número: #{wb_inbox.channel.phone_number}"
  end
end

puts ""

# Verificar se o Socialwise está ativo
if inbox
  account = inbox.account
  puts "3. VERIFICAÇÃO DO SOCIALWISE:"
  
  hook = account.hooks.find_by(app_id: 'socialwise_chatwit', status: 'enabled')
  if hook
    puts "✅ Hook Socialwise encontrado:"
    puts "- ID: #{hook.id}"
    puts "- Status: #{hook.status}"
    puts "- Settings: #{hook.settings.inspect}"
    
    enabled = hook.settings&.dig('enabled')
    webhook_enabled = hook.settings&.dig('webhook_enhancement_enabled')
    
    puts "- Socialwise Enabled: #{enabled}"
    puts "- Webhook Enhancement Enabled: #{webhook_enabled}"
    
    # Testar os métodos do serviço
    service = Integrations::Socialwise::WebhookEnhancerService
    
    puts ""
    puts "4. TESTE DOS MÉTODOS DO SERVIÇO:"
    puts "- socialwise_active?: #{service.socialwise_active?(account)}"
    puts "- webhook_enhancement_enabled?: #{service.webhook_enhancement_enabled?(account)}"
    
  else
    puts "❌ Hook Socialwise NÃO encontrado"
    puts "Hooks disponíveis para a conta:"
    account.hooks.each do |h|
      puts "- App ID: #{h.app_id}, Status: #{h.status}"
    end
  end
else
  puts "3. VERIFICAÇÃO DO SOCIALWISE: Pulada (inbox não encontrada)"
end

puts ""
puts "5. POSSÍVEIS CAUSAS DOS DADOS NULOS:"
puts "- Inbox não encontrada para o número do webhook"
puts "- Socialwise não está ativo para a conta"
puts "- Webhook enhancement está desabilitado"
puts "- Provider config não está configurado"
puts "- Logs do Socialwise não estão sendo exibidos"

puts ""
puts "=== FIM DO DEBUG ==="