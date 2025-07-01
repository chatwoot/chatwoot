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

  def destroy
    ActiveRecord::Base.transaction do
      message.update!(content: I18n.t('conversations.messages.deleted'), content_type: :text, content_attributes: { deleted: true })
      message.attachments.destroy_all
    end
  end

  def retry
    return if message.blank?

    message.update!(status: :sent, content_attributes: {})
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

  def send_email_notification
    conversation = Conversation.find_by(display_id: params[:conversation_id])
    account = conversation.account
    template = EmailTemplate.find_by!(slug: params[:template_slug], account_id: account.id)
    return render json: { error: 'Template not found' }, status: :not_found if template.nil?
    
    recipients = recipients(account).compact
    
    recipients.each do |agent|
      next if agent.nil?
  
      AgentNotifications::CustomMailer.notification_email(
        conversation,
        agent,
        template
      ).deliver_later
    end
    
    render json: { 
      status: 'success', 
      message: 'Email notifications sent successfully',
      recipients: recipients.map(&:email)
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def recipients(account)
    account.account_users.includes(:user).map(&:user).compact
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

  def email_notification_params
    params.permit(:template_slug, :conversation_id)
  end
end
