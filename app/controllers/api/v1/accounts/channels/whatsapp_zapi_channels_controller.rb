class Api::V1::Accounts::Channels::WhatsappZapiChannelsController < Api::V1::Accounts::BaseController
  before_action :authorize_request
  skip_before_action :authorize_request, only: [:webhook]
  skip_before_action :authenticate_user!, only: [:webhook]

  # Criação do canal
  def create
    channel = Current.account.whatsapp_zapi_channels.create!(channel_params)
    inbox = Current.account.inboxes.create!(name: params[:name], channel: channel)
    render json: inbox, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      message: e.record.errors.full_messages.join(', '),
      attributes: e.record.errors.attribute_names
    }, status: :unprocessable_entity
  end

  # Webhook de recebimento do Z-API
  def webhook
    phone = params[:phone] || params.dig(:body, :phone)
    phone = "+#{phone}" unless phone.start_with?('+')
    message = params.dig(:text, :message) || params.dig(:body, :text, :message) || 'Mensagem sem texto'
    instance_id = params[:instanceId] || params[:instance_id] || params.dig(:body, :instanceId) || params.dig(:body, :instance_id)
    sender_name = params.dig(:body, :senderName) || phone
    media_url = params.dig(:body, :mediaUrl)
    media_type = params.dig(:body, :mediaType)
    security_token = request.headers['z-api-token'] || params.dig(:body, :security_token)
    source_id = params[:chatLid] || params.dig(:body, :chatLid) || phone

    # Buscar canal pelo instance_id
    channel = Channel::WhatsappZapi.find_by(instance_id: instance_id)
    Rails.logger.info "[ZAPI DEBUG] instance_id recebido: #{instance_id} | instance_id canal: #{channel&.instance_id}"
    Rails.logger.info "[ZAPI DEBUG] z-api-token recebido: #{security_token} | token canal: #{channel&.token} | security_token canal: #{channel&.security_token}"
    return head :not_found unless channel

    # Validar token de segurança ou token do canal
    unless [channel.security_token, channel.token].include?(security_token)
      Rails.logger.warn '[ZAPI DEBUG] Token inválido!'
      return head :unauthorized
    end

    # Buscar inbox
    inbox = channel.inbox

    begin
      # Buscar ou criar contato
      contact = Contact.find_or_create_by!(phone_number: phone, account_id: channel.account_id) do |c|
        c.name = sender_name
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[ZAPI ERROR] Erro ao criar contato: #{e.record.errors.full_messages.join(', ')}"
      return head :unprocessable_entity
    end

    begin
      # Buscar ou criar ContactInbox
      contact_inbox = ContactInbox.find_or_create_by!(contact: contact, inbox: inbox, source_id: source_id)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[ZAPI ERROR] Erro ao criar ContactInbox: #{e.record.errors.full_messages.join(', ')}"
      return head :unprocessable_entity
    end

    begin
      # Buscar ou criar conversa aberta
      conversation = Conversation.find_or_create_by!(
        contact_inbox: contact_inbox,
        contact: contact,
        status: :open,
        account_id: channel.account_id,
        inbox: inbox
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[ZAPI ERROR] Erro ao criar Conversation: #{e.record.errors.full_messages.join(', ')}"
      return head :unprocessable_entity
    end

    begin
      # Criar mensagem
      msg_params = {
        account_id: channel.account_id,
        inbox_id: inbox.id,
        conversation_id: conversation.id,
        content: message,
        message_type: :incoming,
        sender: contact
      }
      msg = Message.create!(msg_params)
      Rails.logger.info "[ZAPI DEBUG] Mensagem criada: id=#{msg.id} content='#{msg.content}' conversation_id=#{msg.conversation_id} message_type=#{msg.message_type} sender_id=#{msg.sender_id}"
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[ZAPI ERROR] Erro ao criar Message: #{e.record.errors.full_messages.join(', ')}"
      return head :unprocessable_entity
    end

    # Se houver mídia, criar attachment
    if media_url.present? && media_type.present?
      msg.attachments.create!(account_id: channel.account_id, file_type: media_type, external_url: media_url)
    end

    head :ok
  end

  private

  def authorize_request
    authorize ::Inbox
  end

  def channel_params
    params.require(:whatsapp_zapi_channel).permit(:phone_number, :instance_id, :token, :api_url, :security_token, provider_config: {})
  end
end
