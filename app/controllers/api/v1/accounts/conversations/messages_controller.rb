class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_api_inbox, only: :update

  def index
    @messages = message_finder.perform
  end

  def create
    user = Current.user || @resource
    mb = Messages::MessageBuilder.new(user, @conversation, params)
    @message = mb.perform
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def update
    Messages::StatusUpdateService.new(message, permitted_params[:status], permitted_params[:external_error]).perform
    @message = message
  end

  def destroy
    ActiveRecord::Base.transaction do
      message.update!(content: I18n.t('conversations.messages.deleted'), content_type: :text, content_attributes: { deleted: true })
      message.attachments.destroy_all
    end
  end

  def retry
    return if message.blank?

    service = Messages::StatusUpdateService.new(message, 'sent')
    service.perform
    message.update!(content_attributes: {})
    ::SendReplyJob.perform_later(message.id)
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def react
    channel = @conversation.inbox.channel

    unless channel.is_a?(Channel::Whatsapp)
      return render json: { error: 'Reactions are only supported for WhatsApp channels' }, status: :unprocessable_entity
    end
    return render json: { error: 'Message has no source ID' }, status: :unprocessable_entity if message.source_id.blank?

    phone = contact_phone_number
    return render json: { error: 'Contact has no phone number' }, status: :unprocessable_entity if phone.blank?

    send_whatsapp_reaction(channel, phone, permitted_params[:emoji].to_s)
  end

  def translate
    return head :ok if already_translated_content_available?

    translated_content = Integrations::GoogleTranslate::ProcessorService.new(
      message: message,
      target_language: permitted_params[:target_language]
    ).perform

    if translated_content.present?
      translations = {}
      translations[permitted_params[:target_language]] = translated_content
      translations = message.translations.merge!(translations) if message.translations.present?
      message.update!(translations: translations)
    end

    render json: { content: translated_content }
  end

  private

  def message
    @message ||= @conversation.messages.find(permitted_params[:id])
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end

  def permitted_params
    params.permit(:id, :target_language, :status, :external_error, :emoji)
  end

  def already_translated_content_available?
    message.translations.present? && message.translations[permitted_params[:target_language]].present?
  end

  def update_local_reactions(msg, emoji)
    agent_id = "agent_#{Current.user.id}"
    reactions = msg.content_attributes&.dig('reactions') || []
    reactions.reject! { |r| r['sender'] == agent_id }
    reactions << { 'sender' => agent_id, 'emoji' => emoji, 'timestamp' => Time.current.iso8601 } if emoji.present?
    msg.update!(content_attributes: msg.content_attributes.merge('reactions' => reactions))
  end

  def contact_phone_number
    @conversation.contact.phone_number&.delete('+')
  end

  def send_whatsapp_reaction(channel, phone, emoji)
    result = channel.send_reaction(phone, message.source_id, emoji)
    if result
      update_local_reactions(message, emoji)
      render json: { success: true, reactions: message.content_attributes['reactions'] || [] }
    else
      render json: { error: 'Failed to send reaction via WhatsApp' }, status: :unprocessable_entity
    end
  end

  # API inbox check
  def ensure_api_inbox
    # Only API inboxes can update messages
    render json: { error: 'Message status update is only allowed for API inboxes' }, status: :forbidden unless @conversation.inbox.api?
  end
end
