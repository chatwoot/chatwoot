#!/usr/bin/env ruby
# Script para debugar a mensagem 33645

puts "=== DEBUG MENSAGEM 33645 ==="

begin
  message = Message.find(33645)
  
  puts "✅ Mensagem encontrada:"
  puts "  ID: #{message.id}"
  puts "  Content: #{message.content}"
  puts "  Content Type: #{message.content_type}"
  puts "  Content Type (raw): #{message.read_attribute_before_type_cast('content_type')}"
  puts "  Message Type: #{message.message_type}"
  puts "  Account ID: #{message.account_id}"
  puts "  Conversation ID: #{message.conversation_id}"
  puts "  Created At: #{message.created_at}"
  puts "  Updated At: #{message.updated_at}"
  puts ""
  
  puts "Content Attributes:"
  if message.content_attributes.present?
    puts "  Raw: #{message.content_attributes.inspect}"
    puts ""
    
    if message.content_attributes['items']
      puts "  Items (#{message.content_attributes['items'].length}):"
      message.content_attributes['items'].each_with_index do |item, index|
        puts "    #{index + 1}. #{item['title']}"
        puts "       Description: #{item['description']}" if item['description']
        puts "       Media URL: #{item['media_url']}" if item['media_url']
        if item['actions']
          puts "       Actions (#{item['actions'].length}):"
          item['actions'].each do |action|
            puts "         - #{action['type']}: #{action['text']}"
          end
        end
        puts ""
      end
    end
  else
    puts "  ❌ Content attributes vazio"
  end
  
  puts "Additional Attributes:"
  if message.additional_attributes.present?
    puts "  #{message.additional_attributes.inspect}"
  else
    puts "  ❌ Additional attributes vazio"
  end
  puts ""
  
  puts "Processed Message Content:"
  puts "  #{message.processed_message_content}"
  puts ""
  
  # Verificar a conversa
  puts "Conversa:"
  conversation = message.conversation
  puts "  ID: #{conversation.id}"
  puts "  Account ID: #{conversation.account_id}"
  puts "  Status: #{conversation.status}"
  puts ""
  
  # Verificar a conta
  puts "Conta:"
  account = conversation.account
  puts "  ID: #{account.id}"
  puts "  Name: #{account.name}"
  puts "  Feature SOCIALWISE_RICH_DASHBOARD: #{account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')}"
  puts ""
  
  # Simular serialização JSON (como seria enviado ao frontend)
  puts "Serialização JSON (simulada):"
  json_data = {
    id: message.id,
    content: message.content,
    content_type: message.content_type, # Isso deve ser string
    content_attributes: message.content_attributes,
    message_type: message.message_type,
    created_at: message.created_at.to_i
  }
  
  puts "  #{json_data.to_json}"
  puts ""
  
  # Verificar se o content_type é string
  puts "Verificação de tipos:"
  puts "  content_type.class: #{message.content_type.class}"
  puts "  content_type == 'cards': #{message.content_type == 'cards'}"
  puts "  content_type === 'cards': #{message.content_type === 'cards'}"
  puts ""
  
rescue ActiveRecord::RecordNotFound
  puts "❌ Mensagem 33645 não encontrada"
rescue => e
  puts "❌ Erro: #{e.message}"
  puts e.backtrace.first(3)
end

puts "=== FIM DO DEBUG ==="