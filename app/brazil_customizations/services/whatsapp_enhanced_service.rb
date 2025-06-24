# frozen_string_literal: true

module BrazilCustomizations
  # Service para melhorias na integração do WhatsApp para o mercado brasileiro
  class WhatsappEnhancedService
    include BrazilCustomizations::Config
    
    # Templates brasileiros pré-aprovados para WhatsApp
    BRAZILIAN_TEMPLATES = {
      greeting: {
        text: "Olá! 👋 Bem-vindo(a) ao nosso atendimento!\n\nEm que posso ajudá-lo(a) hoje?",
        type: 'text'
      },
      business_hours: {
        text: "📍 *Horário de Atendimento*\n\n" \
              "• Segunda a Sexta: 08h às 18h\n" \
              "• Sábado: 08h às 12h\n" \
              "• Domingo: Fechado\n\n" \
              "Fique à vontade para deixar sua mensagem que retornaremos assim que possível!",
        type: 'text'
      },
      outside_hours: {
        text: "🕐 No momento estamos fora do horário de atendimento.\n\n" \
              "📅 Retornaremos na próxima abertura:\n" \
              "Segunda a Sexta: 08h às 18h\n\n" \
              "Deixe sua mensagem que entraremos em contato!",
        type: 'text'
      },
      queue_position: {
        text: "🕐 Você está na posição *{{position}}* da fila.\n\n" \
              "⏱️ Tempo estimado de espera: *{{wait_time}}* minutos.\n\n" \
              "Obrigado pela paciência! 😊",
        type: 'template'
      },
      document_request: {
        text: "📄 Para prosseguir, preciso de alguns documentos:\n\n" \
              "• CPF ou CNPJ\n" \
              "• Comprovante de endereço\n\n" \
              "Pode enviá-los por aqui mesmo! 📎",
        type: 'text'
      },
      payment_options: {
        text: "💳 *Opções de Pagamento Disponíveis:*\n\n" \
              "• PIX (instantâneo)\n" \
              "• Cartão de Crédito\n" \
              "• Cartão de Débito\n" \
              "• Boleto Bancário\n\n" \
              "Qual você prefere?",
        type: 'text'
      }
    }.freeze
    
    def initialize(account)
      @account = account
      @config = BrazilCustomizations::Config.new
    end
    
    class << self
      # Valida se o número é brasileiro válido para WhatsApp
      def valid_brazilian_whatsapp_number?(phone)
        return false unless phone
        
        # Remove todos os caracteres não numéricos
        clean_number = phone.gsub(/\D/, '')
        
        # Formatos aceitos:
        # 5511999999999 (13 dígitos - com 55 + DDD + 9 + número)
        # 551199999999 (12 dígitos - com 55 + DDD + número sem 9)
        # 11999999999 (11 dígitos - DDD + 9 + número)
        # 1199999999 (10 dígitos - DDD + número sem 9)
        
        case clean_number.length
        when 13
          # +55 11 9 9999-9999
          clean_number.start_with?('55') && clean_number[4] == '9'
        when 12
          # +55 11 9999-9999 (número fixo)
          clean_number.start_with?('55')
        when 11
          # 11 9 9999-9999
          clean_number[2] == '9'
        when 10
          # 11 9999-9999 (número fixo)
          true
        else
          false
        end
      end
      
      # Formata número brasileiro para padrão WhatsApp
      def format_for_whatsapp(phone)
        return nil unless phone
        
        clean = phone.gsub(/\D/, '')
        
        # Se já tem código do país, retorna formatado
        if clean.start_with?('55') && clean.length >= 12
          return "+#{clean}"
        end
        
        # Se não tem código do país, adiciona
        case clean.length
        when 11
          # 11999999999 -> +5511999999999
          "+55#{clean}"
        when 10
          # 1199999999 -> +551199999999
          "+55#{clean}"
        else
          # Retorna original se não conseguir formatar
          phone
        end
      end
      
      # Envia template brasileiro com parâmetros
      def send_brazilian_template(conversation, template_key, params = {})
        template = BRAZILIAN_TEMPLATES[template_key.to_sym]
        return false unless template
        
        message_content = template[:text]
        
        # Substitui parâmetros no template
        params.each do |key, value|
          message_content = message_content.gsub("{{#{key}}}", value.to_s)
        end
        
        # Envia mensagem via Chatwoot
        send_whatsapp_message(conversation, message_content, template[:type])
      end
      
      # Envia saudação baseada no horário brasileiro
      def send_time_based_greeting(conversation)
        greeting = BrazilCustomizations::Config.greeting_for_time
        base_message = BRAZILIAN_TEMPLATES[:greeting][:text]
        
        message = "#{greeting}\n\n#{base_message}"
        send_whatsapp_message(conversation, message, 'text')
      end
      
      # Verifica se está no horário comercial e envia resposta adequada
      def send_business_hours_response(conversation)
        if BrazilCustomizations::Config.within_business_hours?
          send_brazilian_template(conversation, :greeting)
        else
          send_brazilian_template(conversation, :outside_hours)
        end
      end
      
      # Envia posição na fila
      def send_queue_position(conversation, position, estimated_wait_minutes = nil)
        wait_time = estimated_wait_minutes || calculate_estimated_wait(position)
        
        send_brazilian_template(conversation, :queue_position, {
          position: position,
          wait_time: wait_time
        })
      end
      
      # Valida se mensagem contém documento brasileiro
      def extract_brazilian_document(message_content)
        return nil unless message_content
        
        # Procura por padrões de CPF (11 dígitos)
        cpf_match = message_content.scan(/\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b/).first
        if cpf_match && BrazilCustomizations::DocumentValidatorService.valid_cpf?(cpf_match)
          return { type: 'CPF', document: cpf_match, formatted: BrazilCustomizations::DocumentValidatorService.format_cpf(cpf_match) }
        end
        
        # Procura por padrões de CNPJ (14 dígitos)
        cnpj_match = message_content.scan(/\b\d{2}\.?\d{3}\.?\d{3}\/?\d{4}-?\d{2}\b/).first
        if cnpj_match && BrazilCustomizations::DocumentValidatorService.valid_cnpj?(cnpj_match)
          return { type: 'CNPJ', document: cnpj_match, formatted: BrazilCustomizations::DocumentValidatorService.format_cnpj(cnpj_match) }
        end
        
        nil
      end
      
      # Detecta intenção da mensagem (básico)
      def detect_intent(message_content)
        return nil unless message_content
        
        content_lower = message_content.downcase
        
        # Intenções básicas em português
        intents = {
          greeting: %w[oi olá bom boa tchau],
          support: %w[ajuda suporte problema dúvida],
          payment: %w[pagamento pagar pix cartão boleto],
          info: %w[informação preço produto serviço],
          complaint: %w[reclamação problema insatisfeito],
          compliment: %w[parabéns obrigado excelente ótimo]
        }
        
        intents.each do |intent, keywords|
          return intent if keywords.any? { |keyword| content_lower.include?(keyword) }
        end
        
        nil
      end
      
      # Gera quick replies brasileiras baseadas no contexto
      def generate_brazilian_quick_replies(context = nil)
        base_replies = [
          { text: "📞 Falar com atendente", payload: "HUMAN_AGENT" },
          { text: "📋 Informações", payload: "INFO" },
          { text: "💳 Pagamentos", payload: "PAYMENT" },
          { text: "🏪 Horário de funcionamento", payload: "BUSINESS_HOURS" }
        ]
        
        case context
        when :payment
          [
            { text: "💳 PIX", payload: "PIX_PAYMENT" },
            { text: "💳 Cartão", payload: "CARD_PAYMENT" },
            { text: "📄 Boleto", payload: "BOLETO_PAYMENT" },
            { text: "◀️ Voltar", payload: "BACK" }
          ]
        when :support
          [
            { text: "🔧 Suporte técnico", payload: "TECH_SUPPORT" },
            { text: "📦 Pedidos", payload: "ORDERS" },
            { text: "↩️ Trocas e devoluções", payload: "RETURNS" },
            { text: "◀️ Voltar", payload: "BACK" }
          ]
        else
          base_replies
        end
      end
      
      private
      
      # Envia mensagem via WhatsApp através do Chatwoot
      def send_whatsapp_message(conversation, content, message_type = 'text')
        return false unless conversation&.inbox&.channel
        
        # Cria mensagem outgoing
        message = conversation.messages.create!(
          content: content,
          message_type: :outgoing,
          content_type: message_type,
          inbox: conversation.inbox,
          account: conversation.account,
          sender: conversation.assignee || conversation.inbox.members.first
        )
        
        # Envia via canal WhatsApp
        if conversation.inbox.whatsapp?
          conversation.inbox.channel.send_message(message)
        end
        
        true
      rescue StandardError => e
        Rails.logger.error "Error sending WhatsApp message: #{e.message}"
        false
      end
      
      # Calcula tempo estimado de espera baseado na posição
      def calculate_estimated_wait(position)
        # Estimativa: 3 minutos por pessoa na fila
        base_time = 3
        position * base_time
      end
    end

    # Validação de telefone brasileiro
    def validate_brazilian_phone(phone_number)
      return false if phone_number.blank?

      # Remove todos os caracteres não numéricos
      clean_number = phone_number.gsub(/\D/, '')
      
      # Verifica se é um número brasileiro válido (10 ou 11 dígitos)
      return false unless [10, 11].include?(clean_number.length)
      
      # Verifica se começa com código de área válido
      area_code = clean_number[0, 2]
      valid_area_codes = %w[11 12 13 14 15 16 17 18 19 21 22 24 27 28 31 32 33 34 35 37 38 41 42 43 44 45 46 47 48 49 51 53 54 55 61 62 63 64 65 66 67 68 69 71 73 74 75 77 79 81 82 83 84 85 86 87 88 89 91 92 93 94 95 96 97 98 99]
      
      valid_area_codes.include?(area_code)
    end

    # Formata telefone brasileiro para E.164
    def format_brazilian_phone(phone_number)
      return nil if phone_number.blank?

      clean_number = phone_number.gsub(/\D/, '')
      
      # Adiciona código do país se não estiver presente
      clean_number = "55#{clean_number}" unless clean_number.start_with?('55')
      
      # Adiciona + no início
      "+#{clean_number}"
    end

    # Detecta intenção da mensagem para roteamento automático
    def detect_intent(message_content)
      return 'vendas' if sales_keywords.any? { |keyword| message_content.downcase.include?(keyword) }
      return 'suporte' if support_keywords.any? { |keyword| message_content.downcase.include?(keyword) }
      return 'financeiro' if financial_keywords.any? { |keyword| message_content.downcase.include?(keyword) }
      return 'reclamacao' if complaint_keywords.any? { |keyword| message_content.downcase.include?(keyword) }
      
      'geral'
    end

    # Cria template de mensagem inicial baseado na intenção
    def create_welcome_template(intent, contact_name = nil)
      templates = {
        'vendas' => {
          name: 'welcome_sales_pt_br',
          parameters: [
            { type: 'text', text: contact_name || 'Cliente' }
          ]
        },
        'suporte' => {
          name: 'welcome_support_pt_br',
          parameters: [
            { type: 'text', text: contact_name || 'Cliente' }
          ]
        },
        'financeiro' => {
          name: 'welcome_financial_pt_br',
          parameters: [
            { type: 'text', text: contact_name || 'Cliente' }
          ]
        },
        'reclamacao' => {
          name: 'welcome_complaint_pt_br',
          parameters: [
            { type: 'text', text: contact_name || 'Cliente' }
          ]
        },
        'geral' => {
          name: 'welcome_general_pt_br',
          parameters: [
            { type: 'text', text: contact_name || 'Cliente' }
          ]
        }
      }
      
      templates[intent] || templates['geral']
    end

    # Envia mensagem inicial via WhatsApp
    def send_welcome_message(phone_number, intent, contact_name = nil)
      return false unless validate_brazilian_phone(phone_number)

      formatted_phone = format_brazilian_phone(phone_number)
      template = create_welcome_template(intent, contact_name)
      
      # Encontra o canal WhatsApp da conta
      whatsapp_channel = find_whatsapp_channel
      
      if whatsapp_channel
        provider = whatsapp_provider_class(whatsapp_channel).new(whatsapp_channel)
        provider.send_template(formatted_phone, template)
        true
      else
        false
      end
    end

    # Cria conversa e envia mensagem inicial
    def create_conversation_with_welcome(contact_params, message_content, inbox_id = nil)
      # Detecta intenção da mensagem
      intent = detect_intent(message_content)
      
      # Envia mensagem de boas-vindas
      if contact_params[:phone_number].present?
        send_welcome_message(contact_params[:phone_number], intent, contact_params[:name])
      end
      
      # Cria a conversa no Chatwoot
      create_conversation(contact_params, message_content, inbox_id, intent)
    end

    # Preenche informações do contato automaticamente
    def auto_fill_contact_info(phone_number)
      return {} if phone_number.blank?

      # Aqui você pode integrar com APIs externas para buscar informações
      # Por exemplo, consulta CPF/CNPJ, dados de telefone, etc.
      
      # Por enquanto, retorna estrutura básica
      {
        phone_number: format_brazilian_phone(phone_number),
        additional_attributes: {
          country_code: 'BR',
          country: 'Brasil',
          phone_validated: true,
          auto_filled: true
        }
      }
    end

    # Valida e formata CPF/CNPJ
    def validate_document(document_number)
      return { valid: false, type: nil, formatted: nil } if document_number.blank?

      clean_document = document_number.gsub(/\D/, '')
      
      if clean_document.length == 11
        { valid: validate_cpf(clean_document), type: 'cpf', formatted: format_cpf(clean_document) }
      elsif clean_document.length == 14
        { valid: validate_cnpj(clean_document), type: 'cnpj', formatted: format_cnpj(clean_document) }
      else
        { valid: false, type: nil, formatted: nil }
      end
    end

    private

    def sales_keywords
      %w[comprar produto preço valor orçamento proposta venda compra interesse]
    end

    def support_keywords
      %w[ajuda suporte problema erro dificuldade dúvida questionamento]
    end

    def financial_keywords
      %w[pagamento fatura boleto cartão crédito débito transferência dinheiro valor]
    end

    def complaint_keywords
      %w[reclamação problema erro insatisfeito insatisfeita ruim mal atendimento]
    end

    def find_whatsapp_channel
      @account.inboxes.find_by(channel_type: 'Channel::Whatsapp')
    end

    def whatsapp_provider_class(channel)
      case channel.provider
      when 'whatsapp_cloud'
        'Whatsapp::Providers::WhatsappCloudService'
      when '360_dialog'
        'Whatsapp::Providers::Whatsapp360DialogService'
      else
        'Whatsapp::Providers::WhatsappCloudService'
      end.constantize
    end

    def create_conversation(contact_params, message_content, inbox_id, intent)
      # Lógica para criar conversa usando os builders existentes
      # Esta é uma implementação simplificada
      inbox = inbox_id ? @account.inboxes.find(inbox_id) : find_whatsapp_channel&.inbox
      
      return nil unless inbox

      contact = find_or_create_contact(contact_params)
      contact_inbox = find_or_create_contact_inbox(contact, inbox, contact_params[:phone_number])
      
      conversation_params = {
        account_id: @account.id,
        inbox_id: inbox.id,
        contact_id: contact.id,
        contact_inbox_id: contact_inbox.id,
        additional_attributes: {
          intent: intent,
          auto_created: true,
          brazilian_customization: true
        }
      }

      conversation = Conversation.create!(conversation_params)
      
      # Cria a mensagem inicial
      if message_content.present?
        message_params = {
          content: message_content,
          message_type: 'incoming',
          content_type: 'text'
        }
        
        Messages::MessageBuilder.new(contact, conversation, message_params).perform
      end
      
      conversation
    end

    def find_or_create_contact(contact_params)
      # Busca contato existente por email ou telefone
      contact = @account.contacts.find_by(email: contact_params[:email]) if contact_params[:email].present?
      contact ||= @account.contacts.find_by(phone_number: format_brazilian_phone(contact_params[:phone_number])) if contact_params[:phone_number].present?
      
      if contact
        # Atualiza informações se necessário
        contact.update!(contact_params.except(:phone_number).merge(
          phone_number: format_brazilian_phone(contact_params[:phone_number])
        ))
        contact
      else
        # Cria novo contato
        @account.contacts.create!(contact_params.merge(
          phone_number: format_brazilian_phone(contact_params[:phone_number])
        ))
      end
    end

    def find_or_create_contact_inbox(contact, inbox, source_id)
      contact_inbox = ContactInbox.find_by(contact: contact, inbox: inbox)
      
      if contact_inbox
        contact_inbox
      else
        ContactInboxBuilder.new(
          contact: contact,
          inbox: inbox,
          source_id: source_id
        ).perform
      end
    end

    def validate_cpf(cpf)
      return false if cpf.length != 11 || cpf.chars.uniq.length == 1
      
      # Validação de CPF
      sum = 0
      9.times { |i| sum += cpf[i].to_i * (10 - i) }
      remainder = sum % 11
      digit1 = remainder < 2 ? 0 : 11 - remainder
      
      sum = 0
      10.times { |i| sum += cpf[i].to_i * (11 - i) }
      remainder = sum % 11
      digit2 = remainder < 2 ? 0 : 11 - remainder
      
      cpf[9].to_i == digit1 && cpf[10].to_i == digit2
    end

    def validate_cnpj(cnpj)
      return false if cnpj.length != 14 || cnpj.chars.uniq.length == 1
      
      # Validação de CNPJ
      weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
      weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
      
      sum = 0
      12.times { |i| sum += cnpj[i].to_i * weights1[i] }
      remainder = sum % 11
      digit1 = remainder < 2 ? 0 : 11 - remainder
      
      sum = 0
      13.times { |i| sum += cnpj[i].to_i * weights2[i] }
      remainder = sum % 11
      digit2 = remainder < 2 ? 0 : 11 - remainder
      
      cnpj[12].to_i == digit1 && cnpj[13].to_i == digit2
    end

    def format_cpf(cpf)
      "#{cpf[0, 3]}.#{cpf[3, 3]}.#{cpf[6, 3]}-#{cpf[9, 2]}"
    end

    def format_cnpj(cnpj)
      "#{cnpj[0, 2]}.#{cnpj[2, 3]}.#{cnpj[5, 3]}/#{cnpj[8, 4]}-#{cnpj[12, 2]}"
    end
  end
end 