# frozen_string_literal: true

module BrazilCustomizations
  module Controllers
    class BrazilConversationsController < Api::V1::Accounts::BaseController
      include Events::Types

      before_action :set_brazil_service

      # POST /api/v1/accounts/:account_id/brazil_conversations/create_with_welcome
      def create_with_welcome
        contact_params = extract_contact_params
        message_content = params[:message][:content] if params[:message].present?
        inbox_id = params[:inbox_id]

        # Valida telefone brasileiro
        unless @brazil_service.validate_brazilian_phone(contact_params[:phone_number])
          return render json: { error: 'Telefone brasileiro inválido' }, status: :unprocessable_entity
        end

        # Cria conversa com mensagem de boas-vindas
        conversation = @brazil_service.create_conversation_with_welcome(
          contact_params, 
          message_content, 
          inbox_id
        )

        if conversation
          render json: {
            conversation_id: conversation.display_id,
            message: 'Conversa criada com sucesso e mensagem de boas-vindas enviada'
          }
        else
          render json: { error: 'Erro ao criar conversa' }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/accounts/:account_id/brazil_conversations/send_welcome_message
      def send_welcome_message
        phone_number = params[:phone_number]
        intent = params[:intent] || 'geral'
        contact_name = params[:contact_name]

        unless @brazil_service.validate_brazilian_phone(phone_number)
          return render json: { error: 'Telefone brasileiro inválido' }, status: :unprocessable_entity
        end

        success = @brazil_service.send_welcome_message(phone_number, intent, contact_name)

        if success
          render json: { message: 'Mensagem de boas-vindas enviada com sucesso' }
        else
          render json: { error: 'Erro ao enviar mensagem de boas-vindas' }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/accounts/:account_id/brazil_conversations/auto_fill_contact
      def auto_fill_contact
        phone_number = params[:phone_number]
        document_number = params[:document_number]

        result = {}

        # Auto-preenche informações do telefone
        if phone_number.present?
          result[:phone_info] = @brazil_service.auto_fill_contact_info(phone_number)
        end

        # Valida documento se fornecido
        if document_number.present?
          result[:document_info] = @brazil_service.validate_document(document_number)
        end

        render json: result
      end

      # POST /api/v1/accounts/:account_id/brazil_conversations/detect_intent
      def detect_intent
        message_content = params[:message_content]

        if message_content.blank?
          return render json: { error: 'Conteúdo da mensagem é obrigatório' }, status: :unprocessable_entity
        end

        intent = @brazil_service.detect_intent(message_content)

        render json: {
          intent: intent,
          message_content: message_content
        }
      end

      # POST /api/v1/accounts/:account_id/brazil_conversations/validate_phone
      def validate_phone
        phone_number = params[:phone_number]

        if phone_number.blank?
          return render json: { error: 'Número de telefone é obrigatório' }, status: :unprocessable_entity
        end

        is_valid = @brazil_service.validate_brazilian_phone(phone_number)
        formatted_phone = @brazil_service.format_brazilian_phone(phone_number)

        render json: {
          valid: is_valid,
          formatted: formatted_phone,
          original: phone_number
        }
      end

      # POST /api/v1/accounts/:account_id/brazil_conversations/validate_document
      def validate_document
        document_number = params[:document_number]

        if document_number.blank?
          return render json: { error: 'Número do documento é obrigatório' }, status: :unprocessable_entity
        end

        result = @brazil_service.validate_document(document_number)

        render json: result
      end

      private

      def set_brazil_service
        @brazil_service = BrazilCustomizations::Services::WhatsappEnhancedService.new(Current.account)
      end

      def extract_contact_params
        {
          name: params[:contact][:name],
          email: params[:contact][:email],
          phone_number: params[:contact][:phone_number],
          additional_attributes: params[:contact][:additional_attributes] || {}
        }.compact
      end

      def permitted_params
        params.permit(
          :phone_number, :intent, :contact_name, :message_content, :document_number, :inbox_id,
          contact: [:name, :email, :phone_number, additional_attributes: {}],
          message: [:content]
        )
      end
    end
  end
end 