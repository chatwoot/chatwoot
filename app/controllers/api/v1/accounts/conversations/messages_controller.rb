class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
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
    permitted_params = params.require(:message).permit(:content, :source_id, :status, content_attributes: {})
    ActiveRecord::Base.transaction do
      if permitted_params[:content_attributes].present?
        new_content_attributes = message.content_attributes.merge(permitted_params[:content_attributes])
        message.update!(permitted_params.merge(content_attributes: new_content_attributes))
      else
        message.update!(permitted_params)
      end
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      if message.content_attributes['comment_id'].present?
        success = Instagram::DeleteCommentService.new(message).perform
        raise StandardError, 'Failed to delete Instagram comment' unless success
      end

      message.update!(content: I18n.t('conversations.messages.deleted'), content_attributes: { deleted: true })
      message.attachments.destroy_all
    rescue StandardError => e
      render_could_not_create_error(e.message)
    end
  end

  def update_with_source_id
    @message = message_via_source_id
    permitted_params = params.require(:message).permit(:content, :status, content_attributes: {})
    ActiveRecord::Base.transaction do
      if permitted_params[:content_attributes].present?
        new_content_attributes = message.content_attributes.merge(permitted_params[:content_attributes])
        message.update!(permitted_params.merge(content_attributes: new_content_attributes))
      else
        message.update!(permitted_params)
      end
    end
  end

  def retry
    return if message.blank?

    message.update!(status: :sent, content_attributes: {})

    channel_name = message.conversation.inbox.channel.class.to_s

    if channel_name == 'Channel::Api'
      DelayDispatchEventJob.perform_later(event_name: 'message.created', timestamp: Time.zone.now, message_id: message.id)
    else
      ::SendReplyJob.perform_later(message.id)
    end
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

  private

  def message_via_source_id
    @message_via_source_id ||= @conversation.messages.find_by(source_id: permitted_params[:id])
  end

  def message
    @message ||= @conversation.messages.find(permitted_params[:id])
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end

  def permitted_params
    params.permit(:id, :target_language)
  end

  def already_translated_content_available?
    message.translations.present? && message.translations[permitted_params[:target_language]].present?
  end
end
