class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_api_inbox, only: :update

  def index
    @messages = message_finder.perform
  end

  def create
    user = Current.user || @resource

    # Use Apple Messages processor for automatic URL-to-Rich Link conversion
    if @conversation.inbox.channel_type == 'Channel::AppleMessagesForBusiness'
      processor = AppleMessagesForBusiness::MessageProcessorService.new(@conversation, create_params, user)
      @message = processor.process_and_send

      # Handle multiple messages case
      if @message.is_a?(Array)
        @message = @message.last # Return the last message for response
      end
    else
      # Regular message creation for non-Apple Messages conversations
      mb = Messages::MessageBuilder.new(user, @conversation, create_params)
      @message = mb.perform
    end
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
    params.permit(:id, :target_language, :status, :external_error)
  end

  def create_params
    Rails.logger.info "🔥 MessagesController create_params called with: #{params.inspect}"
    Rails.logger.info "🔥 MessagesController content_attributes: #{params[:content_attributes]}"
    Rails.logger.info "🔥 MessagesController images in content_attributes: #{params.dig(:content_attributes, :images)}"

    permitted = params.permit(:content, :private, :message_type, :content_type, :echo_id, :sender_type, :sender_id, :external_created_at,
                              :attachments => [],
                              :content_attributes => [
                                # Apple Quick Reply
                                :summary_text, { :items => [:title, :identifier, :description] },
                                # Apple List Picker
                                { :sections => [:title, :multiple_selection, { :items => [:title, :subtitle, :identifier, :imageIdentifier] }] },
                                { :images => [:identifier, :data, :description] },  # Fixed: Allow nested image structure
                                # Apple Time Picker
                                { :event => [:title, :description, :identifier, { :timeslots => [:startTime, :duration] }] },
                                :timezone_offset,
                                # Apple Rich Link
                                :url, :title, :description, :image_url, :site_name,
                                # Apple Form - MISSING FIELDS ADDED
                                :title, :description, :submit_url, :method, :validation_rules,
                                { :fields => [:type, :name, :label, :placeholder, :required, :default, :pattern, :title, :pattern_error, { :options => [:value, :title] }] },
                                # Apple Custom App
                                :app_id, :app_name, :bid, :use_live_layout,
                                # Common Apple Messages fields
                                :received_title, :received_subtitle, :received_image_identifier, :received_style,
                                :reply_title, :reply_subtitle, :reply_style,
                                :reply_image_title, :reply_image_subtitle,
                                :reply_secondary_subtitle, :reply_tertiary_subtitle
                              ])

    Rails.logger.info "🔥 MessagesController permitted params: #{permitted.inspect}"
    Rails.logger.info "🔥 MessagesController permitted content_attributes: #{permitted[:content_attributes]}"
    Rails.logger.info "🔥 MessagesController permitted images: #{permitted.dig(:content_attributes, :images)}"

    permitted
  end

  def already_translated_content_available?
    message.translations.present? && message.translations[permitted_params[:target_language]].present?
  end

  # API inbox check
  def ensure_api_inbox
    # Only API inboxes can update messages
    render json: { error: 'Message status update is only allowed for API inboxes' }, status: :forbidden unless @conversation.inbox.api?
  end
end
