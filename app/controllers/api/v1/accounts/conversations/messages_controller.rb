class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  include Events::Types

  before_action :ensure_api_inbox, only: :update

  def index
    @messages = message_finder.perform
  end

  def create
    user = Current.user || @resource
    mb = Messages::MessageBuilder.new(user, @conversation, params)
    @message = mb.perform

    trigger_typing_event(CONVERSATION_TYPING_OFF)
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
    delete_message_on_channel
  end

  def retry
    return if message.blank?
    return head :unprocessable_entity unless message.failed? && (message.outgoing? || message.template?)

    service = Messages::StatusUpdateService.new(message, 'sent')
    service.perform
    message.update!(content_attributes: {}, source_id: nil)
    ::SendReplyJob.perform_later(message.id)
  rescue StandardError => e
    render_could_not_create_error(e.message)
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

  def edit_content
    new_content = params[:content]
    return render json: { error: 'Content is required' }, status: :unprocessable_entity if new_content.blank?
    return render json: { error: 'Content exceeds maximum length' }, status: :unprocessable_entity if new_content.length > 150_000
    return render json: { error: 'Only outgoing messages can be edited' }, status: :forbidden unless message.outgoing?

    original_content = message.content
    # Only save previous_content on first edit to preserve the original message
    previous_content_to_save = message.is_edited ? message.previous_content : original_content
    message.update!(content: new_content, is_edited: true, previous_content: previous_content_to_save)

    edit_message_on_channel(new_content, original_content)

    @message = message.reload
  end

  private

  def message
    @message ||= @conversation.messages.find(permitted_params[:id])
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end

  def permitted_params
    params.permit(:id, :target_language, :status, :external_error, :content)
  end

  def already_translated_content_available?
    message.translations.present? && message.translations[permitted_params[:target_language]].present?
  end

  def delete_message_on_channel
    return unless @conversation.inbox.channel.respond_to?(:delete_message)
    return if message.source_id.blank?

    @conversation.inbox.channel.delete_message(message, conversation: @conversation)
  rescue StandardError => e
    Rails.logger.error "Failed to delete message on channel: #{e.message}"
  end

  def edit_message_on_channel(new_content, original_content)
    return unless @conversation.inbox.channel.respond_to?(:edit_message)
    return if message.source_id.blank?

    @conversation.inbox.channel.edit_message(message, new_content, conversation: @conversation)
  rescue StandardError => e
    Rails.logger.error "Failed to edit message on channel: #{e.message}"
    was_already_edited = message.previous_content != original_content
    if was_already_edited
      message.update!(content: original_content)
    else
      message.update!(content: original_content, is_edited: false, previous_content: nil)
    end
    raise e
  end

  # API inbox check
  def ensure_api_inbox
    # Only API inboxes can update messages
    render json: { error: 'Message status update is only allowed for API inboxes' }, status: :forbidden unless @conversation.inbox.api?
  end

  def trigger_typing_event(event)
    user = Current.user || @resource
    return unless user.is_a?(User)

    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: user, is_private: params[:private])
  end
end
