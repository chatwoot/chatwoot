#!/usr/bin/env ruby

# Debug detalhado do InstagramResponseProcessor

require_relative 'config/environment'

puts "=== Debug Instagram Response Processor ==="

# Payload reestruturado (formato correto)
restructured_payload = {
  'message_format' => 'GENERIC_TEMPLATE',
  'payload' => {
    'template_type' => 'generic',
    'elements' => [
      {
        'title' => 'Teste de mensagem rica',
        'subtitle' => 'Subtítulo do teste',
        'buttons' => [
          {
            'type' => 'postback',
            'title' => 'Clique aqui',
            'payload' => 'test_payload_123'
          }
        ],
        'image_url' => 'https://example.com/image.jpg'
      }
    ]
  }
}

puts "\n1. Payload reestruturado:"
puts restructured_payload.inspect

# Testar validação
puts "\n2. Testando validação do payload..."

message_format = restructured_payload['message_format']
payload = restructured_payload['payload']

puts "   message_format: #{message_format}"
puts "   payload keys: #{payload.keys.inspect}"

# Testar validação específica
begin
  puts "\n3. Testando validate_payload..."
  
  # Simular o que acontece no validate_payload
  puts "   Payload é Hash? #{payload.is_a?(Hash)}"
  
  case message_format
  when 'GENERIC_TEMPLATE'
    puts "   Testando validate_generic_template..."
    puts "     template_type: #{payload['template_type']}"
    puts "     elements é Array? #{payload['elements'].is_a?(Array)}"
    puts "     elements não vazio? #{payload['elements']&.any?}"
    puts "     elements count: #{payload['elements']&.length}"
    
    if payload['elements']&.any?
      payload['elements'].each_with_index do |element, index|
        puts "     Element #{index}:"
        puts "       title presente? #{element['title'].present?}"
        puts "       title: #{element['title']}"
        puts "       buttons é Array? #{element['buttons'].is_a?(Array)}"
        puts "       buttons count: #{element['buttons']&.length}"
      end
    end
  end
  
rescue => e
  puts "   ❌ ERRO na validação: #{e.class}: #{e.message}"
end

# Testar o método process diretamente
puts "\n4. Testando InstagramResponseProcessor.process diretamente..."

# Criar dados mínimos
account = Account.first
inbox = account.inboxes.find_by(channel_type: 'Channel::FacebookPage')
contact = inbox.contacts.first
conversation = contact.conversations.first
message = conversation.messages.create!(
  content: 'Test',
  message_type: :incoming,
  account_id: account.id,
  inbox_id: inbox.id
)

begin
  # Habilitar logs detalhados
  Rails.logger.level = Logger::INFO
  
  puts "   Chamando InstagramResponseProcessor.process..."
  success = Integrations::Socialwise::InstagramResponseProcessor.process(restructured_payload, message)
  puts "   Resultado: #{success}"
  
  # Verificar mensagens criadas
  recent_messages = conversation.messages.where('created_at > ?', 30.seconds.ago)
  puts "   Mensagens recentes: #{recent_messages.count}"
  
  recent_messages.each do |msg|
    puts "     Mensagem #{msg.id}: #{msg.content_type} - #{msg.content}"
  end
  
rescue => e
  puts "   ❌ ERRO: #{e.class}: #{e.message}"
  puts "   Backtrace: #{e.backtrace.first(10).join('\n   ')}"
end

puts "\n=== Fim do Debug ==="