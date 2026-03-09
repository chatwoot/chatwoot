#!/usr/bin/env ruby
# Script para debugar especificamente o WhatsApp Interactive

puts "=== DEBUG WHATSAPP INTERACTIVE ==="
puts

# Simular exatamente o que o SocialWise Flow faz
puts "1. Simulando criação de mensagem com padrão Instagram:"

# Payload de exemplo
whatsapp_interactive_payload = {
  'type' => 'button',
  'body' => {
    'text' => 'Olá! Como posso ajudar você hoje?'
  },
  'action' => {
    'buttons' => [
      {
        'type' => 'reply',
        'reply' => {
          'id' => 'btn_1',
          'title' => 'Falar com Atendente'
        }
      }
    ]
  }
}

puts "   Payload de entrada:"
puts JSON.pretty_generate(whatsapp_interactive_payload)
puts

# Testar o mapper
begin
  mapped_result = Messages::WhatsappRendererMapper.map(whatsapp_interactive_payload)
  
  puts "2. Resultado do WhatsappRendererMapper:"
  puts "   Content Type: #{mapped_result.content_type}"
  puts "   Fallback Text: #{mapped_result.fallback_text}"
  puts "   Content Attributes:"
  
  mapped_result.content_attributes.each do |key, value|
    puts "     #{key}: #{value.class}"
    if key == 'whatsapp_interactive_payload'
      puts "       ✅ Presente - WhatsAppInteractive.vue vai renderizar"
    elsif key == 'interactive'
      puts "       ✅ Presente - Fallback para renderização"
    elsif key == 'interactive_payload'
      puts "       ✅ Presente - Evita atualização no RichMessageService"
    end
  end
  puts
  
  puts "3. Verificando lógica do Message.vue:"
  content_type = mapped_result.content_type
  content_attributes = mapped_result.content_attributes
  
  puts "   contentType === 'integrations': #{content_type == 'integrations'}"
  
  has_whatsapp_interactive = content_attributes['whatsapp_interactive_payload'] || content_attributes['interactive']
  puts "   hasWhatsAppInteractive: #{!!has_whatsapp_interactive}"
  
  if content_type == 'integrations' && has_whatsapp_interactive
    puts "   ✅ RESULTADO: WhatsAppInteractive.vue será renderizado"
  else
    puts "   ❌ PROBLEMA: WhatsAppInteractive.vue NÃO será renderizado"
  end
  puts
  
  puts "4. Verificando estrutura para WhatsAppInteractive.vue:"
  interactive_payload = content_attributes['whatsapp_interactive_payload'] || content_attributes['interactive']
  
  if interactive_payload
    puts "   Payload encontrado:"
    puts "   - Tipo: #{interactive_payload['type']}"
    puts "   - Body text: #{interactive_payload.dig('body', 'text')}"
    puts "   - Botões: #{interactive_payload.dig('action', 'buttons')&.length || 0}"
    
    if interactive_payload['type'] == 'button'
      puts "   ✅ Template de botão - será renderizado corretamente"
    elsif interactive_payload['type'] == 'list'
      puts "   ✅ Template de lista - será renderizado corretamente"
    else
      puts "   ⚠️  Tipo desconhecido: #{interactive_payload['type']}"
    end
  else
    puts "   ❌ Nenhum payload interativo encontrado"
  end
  
rescue => e
  puts "❌ Erro no mapper: #{e.class}: #{e.message}"
  puts "   Backtrace: #{e.backtrace.first(3).join('\n')}"
end

puts
puts "5. Verificando mensagens reais no banco:"

# Buscar mensagem mais recente do SocialWise Flow
recent_message = Message.joins(:conversation)
                       .joins('JOIN inboxes ON conversations.inbox_id = inboxes.id')
                       .where('inboxes.channel_type = ?', 'Channel::Whatsapp')
                       .where('messages.additional_attributes @> ?', { socialwise_flow_message: true }.to_json)
                       .where('messages.created_at > ?', 1.hour.ago)
                       .order(created_at: :desc)
                       .first

if recent_message
  puts "   Mensagem mais recente encontrada:"
  puts "   - ID: #{recent_message.id}"
  puts "   - Content Type: #{recent_message.content_type}"
  puts "   - Criada: #{recent_message.created_at}"
  puts "   - Conteúdo: #{recent_message.content&.truncate(50)}"
  puts
  
  puts "   Content Attributes:"
  recent_message.content_attributes.each do |key, value|
    puts "     #{key}: #{value.class}"
  end
  puts
  
  puts "   Verificação para renderização:"
  puts "   - contentType === 'integrations': #{recent_message.content_type == 'integrations'}"
  
  has_payload = recent_message.content_attributes['whatsapp_interactive_payload'] || recent_message.content_attributes['interactive']
  puts "   - hasWhatsAppInteractive: #{!!has_payload}"
  
  if recent_message.content_type == 'integrations' && has_payload
    puts "   ✅ Esta mensagem DEVE ser renderizada como WhatsAppInteractive"
  else
    puts "   ❌ Esta mensagem NÃO será renderizada como WhatsAppInteractive"
  end
  
else
  puts "   ℹ️  Nenhuma mensagem SocialWise Flow encontrada na última hora"
end

puts
puts "=== CONCLUSÃO ==="
puts "Se o teste acima mostrar ✅ para tudo, então:"
puts "1. O mapper está funcionando corretamente"
puts "2. As mensagens estão sendo criadas com estrutura correta"
puts "3. O Message.vue deve renderizar WhatsAppInteractive.vue"
puts "4. O problema pode estar no front-end (JavaScript/Vue.js)"
puts
puts "Para debugar o front-end:"
puts "1. Abra o navegador (F12 → Console)"
puts "2. Procure por erros de JavaScript"
puts "3. Verifique se o componente WhatsAppInteractive está sendo chamado"
puts "4. Verifique se os dados estão chegando corretamente no Vue.js"