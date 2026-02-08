#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== VERIFICAÇÃO DA INBOX 4 ==="
puts ""

begin
  inbox = Inbox.find(4)
  puts "✅ Inbox encontrada:"
  puts "- ID: #{inbox.id}"
  puts "- Nome: #{inbox.name}"
  puts "- Channel Type: #{inbox.channel_type}"
  puts "- Account ID: #{inbox.account_id}"
  
  if inbox.channel
    puts "- Channel presente: ✅"
    puts "- Channel class: #{inbox.channel.class}"
    
    if inbox.channel.provider_config.present?
      puts "- Provider Config presente: ✅"
      puts "- API Key: #{inbox.channel.provider_config['api_key'].present? ? 'Presente' : 'Ausente'}"
      puts "- Phone Number ID: #{inbox.channel.provider_config['phone_number_id'] || 'Ausente'}"
      puts "- Business Account ID: #{inbox.channel.provider_config['business_account_id'] || 'Ausente'}"
      puts "- Provider Config completo: #{inbox.channel.provider_config.inspect}"
    else
      puts "- Provider Config: ❌ AUSENTE"
    end
  else
    puts "- Channel: ❌ AUSENTE"
  end
  
  puts ""
  puts "=== TESTE DO CACHE ==="
  service = Integrations::Socialwise::WebhookEnhancerService
  cached_config = service.send(:get_cached_provider_config, 4)
  puts "Cache result: #{cached_config.inspect}"
  
rescue ActiveRecord::RecordNotFound
  puts "❌ Inbox 4 não encontrada"
rescue => e
  puts "❌ Erro: #{e.class}: #{e.message}"
end