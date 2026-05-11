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
    emoji = params[:emoji]
    return head :bad_request if emoji.blank?

    reactions = (message.content_attributes['reactions'] || []).dup
    sender_identifier = "agent:#{Current.user&.id}"

    # Remove existing reaction from this agent
    reactions.reject! { |r| r['sender_source_id'] == sender_identifier }

    # Add new reaction (empty emoji means unreact)
    if emoji != 'remove'
      reactions << {
        'emoji' => emoji,
        'sender_source_id' => sender_identifier,
        'sender_name' => Current.user&.name,
        'timestamp' => Time.current.to_i
      }
    end

    message.content_attributes = message.content_attributes.merge('reactions' => reactions)
    message.save!
    message.send_update_event

    # Send reaction to channel if supported
    send_reaction_to_channel(emoji)

    head :ok
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

  # API inbox check
  def ensure_api_inbox
    # Only API inboxes can update messages
    render json: { error: 'Message status update is only allowed for API inboxes' }, status: :forbidden unless @conversation.inbox.api?
  end

  def send_reaction_to_channel(emoji)
    channel = @conversation.inbox.channel
    return unless message.source_id.present?

    case channel
    when Channel::Whatsapp
      contact = @conversation.contact
      phone_number = contact.phone_number&.delete('+')
      return unless phone_number.present?

      reaction_emoji = emoji == 'remove' ? '' : emoji
      channel.provider_service.send_reaction(phone_number, message.source_id, reaction_emoji)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to send reaction to channel: #{e.message}"
  end
end
