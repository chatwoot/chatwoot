namespace :debug do
  desc "Debug Dialogflow Payload - Testa payload expandido enviado ao Dialogflow"
  task :dialogflow_payload => :environment do
    puts "🔍 Debug Dialogflow Payload - Payload Expandido"
    puts "=" * 60
    
    # Busca conta, inbox e mensagem de teste
    account = Account.find(2)
    inbox = account.inboxes.find(2)
    conversation = inbox.conversations.last
    message = conversation.messages.last
    
    puts "📋 Informações do Teste:"
    puts "Account: #{account.name} (ID: #{account.id})"
    puts "Inbox: #{inbox.name} (ID: #{inbox.id})"
    puts "Conversation: #{conversation.id}"
    puts "Message: #{message.id} - '#{message.content}'"
    puts "Contact: #{conversation.contact.name} (#{conversation.contact.phone_number})"
    puts ""
    
    # Verifica se hook Socialwise está ativo
    socialwise_hook = account.hooks.find_by(app_id: 'socialwise_chatwit', status: 'enabled')
    
    if socialwise_hook
      puts "✅ Hook Socialwise encontrado (ID: #{socialwise_hook.id})"
      puts "   Settings: #{socialwise_hook.settings.inspect}"
      puts ""
      
      # Simula o processamento do Dialogflow
      puts "🧠 Simulando processamento Dialogflow..."
      
      # Cria uma instância do processor
      processor = Integrations::Dialogflow::ProcessorService.new(
        event_name: 'message.created',
        hook: account.hooks.find_by(app_id: 'dialogflow'),
        event_data: { message: message }
      )
      
      # Testa se Socialwise está habilitado
      if processor.send(:socialwise_chatwit_enabled?)
        puts "✅ Socialwise habilitado - construindo payload expandido..."
        
        # Constrói o payload expandido
        payload = processor.send(:build_whatsapp_payload_data)
        
        puts ""
        puts "📦 PAYLOAD EXPANDIDO CONSTRUÍDO:"
        puts "=" * 60
        puts "Total de campos: #{payload.keys.size}"
        puts ""
        
        # Organiza os campos por categoria
        categories = {
          "WhatsApp IDs" => payload.select { |k, v| k.include?('wamid') || k.include?('whatsapp_id') },
          "Dados do Contato" => payload.select { |k, v| k.start_with?('contact_') },
          "Custom Attributes" => payload.select { |k, v| ['status_typebot', 'lead_status', 'customer_type', 'segment', 'priority'].include?(k) },
          "Dados da Conversa" => payload.select { |k, v| k.start_with?('conversation_') },
          "Dados do Assignee" => payload.select { |k, v| k.start_with?('assignee_') },
          "Dados do Team" => payload.select { |k, v| k.start_with?('team_') },
          "Dados da Mensagem" => payload.select { |k, v| k.start_with?('message_') },
          "Dados do Inbox" => payload.select { |k, v| k.start_with?('inbox_') },
          "Dados da Conta" => payload.select { |k, v| k.start_with?('account_') },
          "Dados WhatsApp Canal" => payload.select { |k, v| k.start_with?('whatsapp_') },
          "Metadados" => payload.select { |k, v| ['socialwise_active', 'is_whatsapp_channel', 'current_time', 'timezone'].include?(k) },
          "Indicadores" => payload.select { |k, v| ['response_time_exceeded', 'vip_customer', 'high_priority', 'is_business_hours'].include?(k) }
        }
        
        categories.each do |category, fields|
          next if fields.empty?
          
          puts "📂 #{category}:"
          fields.each do |key, value|
            # Formata o valor para exibição
            display_value = case value
            when Hash
              value.empty? ? "{}" : "{ #{value.keys.first}: #{value.values.first}, ... } (#{value.keys.size} campos)"
            when Array
              value.empty? ? "[]" : "[#{value.first}, ...] (#{value.size} itens)"
            when String
              value.length > 50 ? "#{value[0..47]}..." : value
            else
              value
            end
            
            puts "   #{key}: #{display_value}"
          end
          puts ""
        end
        
        puts "🎯 CAMPOS MAIS IMPORTANTES PARA DIALOGFLOW:"
        puts "=" * 60
        important_fields = [
          'status_typebot', 'contact_name', 'contact_phone', 'conversation_status',
          'conversation_priority', 'assignee_name', 'team_name', 'is_business_hours',
          'response_time_exceeded', 'vip_customer', 'high_priority', 'conversation_labels'
        ]
        
        important_fields.each do |field|
          if payload.key?(field)
            puts "✅ #{field}: #{payload[field]}"
          else
            puts "❌ #{field}: (não encontrado)"
          end
        end
        
        puts ""
        puts "📊 ESTATÍSTICAS DO PAYLOAD:"
        puts "Total de campos: #{payload.keys.size}"
        puts "Campos com dados: #{payload.select { |k, v| !v.nil? && v != '' }.size}"
        puts "Campos vazios: #{payload.select { |k, v| v.nil? || v == '' }.size}"
        puts "Campos booleanos: #{payload.select { |k, v| v.is_a?(TrueClass) || v.is_a?(FalseClass) }.size}"
        puts "Campos numéricos: #{payload.select { |k, v| v.is_a?(Numeric) }.size}"
        puts "Campos de texto: #{payload.select { |k, v| v.is_a?(String) }.size}"
        puts "Campos de hash: #{payload.select { |k, v| v.is_a?(Hash) }.size}"
        puts "Campos de array: #{payload.select { |k, v| v.is_a?(Array) }.size}"
        
      else
        puts "❌ Socialwise não está habilitado"
      end
    else
      puts "❌ Hook Socialwise não encontrado"
    end
    
    puts ""
    puts "🎉 Debug concluído!"
  end
end 