#!/usr/bin/env ruby
# Script para verificar mensagens com content_type cards

puts "=== VERIFICANDO MENSAGENS COM CONTENT_TYPE CARDS ==="

# Buscar mensagens com content_type cards
cards_messages = Message.where(content_type: 'cards').order(created_at: :desc).limit(10)

puts "Mensagens encontradas: #{cards_messages.count}"
puts ""

if cards_messages.any?
  cards_messages.each do |message|
    puts "Mensagem ID: #{message.id}"
    puts "  Content: #{message.content.truncate(50)}"
    puts "  Content Type: #{message.content_type}"
    puts "  Account ID: #{message.account_id}"
    puts "  Conversation ID: #{message.conversation_id}"
    puts "  Created At: #{message.created_at}"
    
    if message.content_attributes['items']
      puts "  Items: #{message.content_attributes['items'].length}"
      message.content_attributes['items'].each_with_index do |item, index|
        puts "    #{index + 1}. #{item['title']}"
      end
    end
    puts ""
  end
else
  puts "❌ Nenhuma mensagem com content_type 'cards' encontrada"
  
  # Verificar se existem mensagens com content_type como integer
  puts "\nVerificando mensagens com content_type como integer..."
  
  # O enum 'cards' tem valor 5
  cards_int_messages = Message.where(content_type: 5).order(created_at: :desc).limit(5)
  
  puts "Mensagens com content_type = 5 (cards): #{cards_int_messages.count}"
  
  cards_int_messages.each do |message|
    puts "Mensagem ID: #{message.id}"
    puts "  Content Type (raw): #{message.read_attribute_before_type_cast('content_type')}"
    puts "  Content Type (enum): #{message.content_type}"
    puts "  Content: #{message.content.truncate(50)}"
    puts ""
  end
end

# Verificar todas as mensagens recentes da conta 3
puts "\n=== MENSAGENS RECENTES DA CONTA 3 ==="
recent_messages = Message.joins(:conversation)
                         .where(conversations: { account_id: 3 })
                         .order(created_at: :desc)
                         .limit(5)

recent_messages.each do |message|
  puts "Mensagem ID: #{message.id}"
  puts "  Content Type: #{message.content_type} (#{message.read_attribute_before_type_cast('content_type')})"
  puts "  Content: #{message.content.truncate(50)}"
  puts "  Message Type: #{message.message_type}"
  puts "  Created At: #{message.created_at}"
  puts "  Has content_attributes: #{message.content_attributes.present?}"
  if message.content_attributes.present? && message.content_attributes['items']
    puts "  Items count: #{message.content_attributes['items'].length}"
  end
  puts ""
end

puts "=== FIM DA VERIFICAÇÃO ==="