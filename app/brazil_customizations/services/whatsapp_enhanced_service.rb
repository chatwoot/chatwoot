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
  end
end 