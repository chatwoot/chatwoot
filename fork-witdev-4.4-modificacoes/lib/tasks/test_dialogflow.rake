namespace :test do
  desc "Testa integração Dialogflow simulando mensagem WhatsApp"
  task dialogflow: :environment do
    puts "=========================================="
    puts "  TESTE DIALOGFLOW - SIMULACAO WHATSAPP"
    puts "=========================================="
    
    # Busca pela inbox "witdev"
    inbox = Inbox.find_by(name: "witdev")
    if inbox.nil?
      puts "[ERRO] Inbox 'witdev' nao encontrada!"
      puts "Inboxes disponiveis: #{Inbox.pluck(:name).join(', ')}"
      exit
    end
    
    puts "[OK] Inbox encontrada: #{inbox.name} (ID: #{inbox.id})"
    puts "[INFO] Tipo do canal: #{inbox.channel_type}"
    
    # Busca pelo contato existente (evita criar duplicados)
    contact = Contact.find_by(account: inbox.account, phone_number: "+558597550136")
    if contact.nil?
      # Se não encontrar, busca por qualquer contato da conta
      contact = Contact.where(account: inbox.account).first
      if contact.nil?
        puts "[INFO] Criando novo contato de teste..."
        contact = Contact.create!(
          account: inbox.account,
          name: "Teste Dialogflow",
          phone_number: "+558597550136",
          identifier: "558597550136@s.whatsapp.net",
          custom_attributes: {
            "status_typebot" => "Ligado"
          }
        )
      else
        puts "[OK] Usando contato existente: #{contact.name}"
        # Atualiza para ter o custom_attributes necessário
        contact.update!(custom_attributes: (contact.custom_attributes || {}).merge("status_typebot" => "Ligado"))
      end
    else
      puts "[OK] Contato encontrado: #{contact.name}"
      
      # Atualiza custom_attributes se necessário
      contact.update!(custom_attributes: (contact.custom_attributes || {}).merge("status_typebot" => "Ligado"))
      puts "[INFO] Custom attributes atualizados"
    end
    
    puts "[DATA] Contact custom_attributes: #{contact.custom_attributes.inspect}"
    
    # Busca ou cria contact_inbox
    contact_inbox = ContactInbox.find_by(contact: contact, inbox: inbox)
    if contact_inbox.nil?
      puts "[INFO] Criando contact_inbox..."
      contact_inbox = ContactInbox.create!(
        contact: contact,
        inbox: inbox,
        source_id: "teste-dialogflow-#{Time.now.to_i}"
      )
    else
      puts "[OK] Contact inbox encontrado: #{contact_inbox.source_id}"
    end
    
    # Busca ou cria conversa
    conversation = Conversation.find_by(contact_inbox: contact_inbox, inbox: inbox)
    if conversation.nil?
      puts "[INFO] Criando nova conversa..."
      conversation = Conversation.create!(
        account: inbox.account,
        inbox: inbox,
        contact_inbox: contact_inbox,
        contact: contact,
        status: :open
      )
    else
      puts "[OK] Conversa encontrada: #{conversation.id}"
    end
    
    # Busca pelos hooks
    puts ""
    puts "[INFO] Verificando hooks..."
    dialogflow_hook = Integrations::Hook.find_by(account: inbox.account, app_id: 'dialogflow')
    socialwise_hook = Integrations::Hook.find_by(account: inbox.account, app_id: 'socialwise_chatwit')
    
    if dialogflow_hook.nil?
      puts "[ERRO] Hook Dialogflow nao encontrado!"
      exit
    end
    
    if socialwise_hook.nil?
      puts "[ERRO] Hook Socialwise nao encontrado!"
      exit
    end
    
    puts "[OK] Hook Dialogflow: #{dialogflow_hook.status}"
    puts "[OK] Hook Socialwise: #{socialwise_hook.status} (enabled: #{socialwise_hook.settings&.dig('enabled')})"
    
    # Cria uma mensagem de teste
    puts ""
    puts "[INFO] Criando mensagem de teste..."
    wamid = "WAID:TESTE#{Time.now.to_i}#{rand(1000)}"
    message_content = "exibirpayload"
    
    message = Message.create!(
      account: inbox.account,
      inbox: inbox,
      conversation: conversation,
      message_type: :incoming,
      content: message_content,
      source_id: wamid,
      sender: contact,
      content_type: :text
    )
    
    puts "[OK] Mensagem criada: ID #{message.id}"
    puts "[DATA] Source ID (WAMID): #{message.source_id}"
    puts "[DATA] Conteudo: #{message.content}"
    
    # Testa o processamento do Dialogflow diretamente
    puts ""
    puts "[TEST] Testando processamento Dialogflow..."
    
    begin
      # Simula o event_data como seria no HookJob
      event_data = {
        message: message
      }
      
      # Chama o serviço diretamente
      processor = Integrations::Dialogflow::ProcessorService.new(
        event_name: 'message.created',
        hook: dialogflow_hook,
        event_data: event_data
      )
      
      puts "[TEST] Processando com Dialogflow..."
      
      # Chama o método private através de send (apenas para teste)
      session_id = contact_inbox.source_id
      response = processor.send(:get_response, session_id, message_content)
      
      if response
        puts "[OK] Resposta recebida do Dialogflow!"
        puts "[DATA] Resposta: #{response.inspect}"
      else
        puts "[WARN] Nenhuma resposta recebida do Dialogflow"
      end
      
    rescue => e
      puts "[ERRO] Erro ao processar Dialogflow: #{e.message}"
      puts "[DEBUG] Backtrace: #{e.backtrace.first(5).join('\n')}"
    end
    
    puts ""
    puts "[DONE] Teste concluido!"
    puts "[INFO] Verifique os logs do Sidekiq para detalhes do processamento"
  end
end 