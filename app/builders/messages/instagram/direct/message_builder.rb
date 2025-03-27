class Messages::Instagram::Direct::MessageBuilder < Messages::Messenger::MessageBuilder
  attr_reader :messaging

  include HTTParty

  base_uri "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"

  def initialize(messaging, inbox, outgoing_echo: false)
    super()
    @messaging = messaging
    @inbox = inbox
    @outgoing_echo = outgoing_echo
  end

  def perform
    return if @inbox.channel.reauthorization_required?

    ActiveRecord::Base.transaction do
      build_message
    end
  rescue StandardError => e
    handle_error(e)
  end

  private

  def attachments
    @messaging[:message][:attachments] || {}
  end

  def message_type
    @outgoing_echo ? :outgoing : :incoming
  end

  def get_story_object_from_source_id(source_id)
    url = "#{self.class.base_uri}/#{source_id}?fields=story,from&access_token=#{@inbox.channel.access_token}"
    response = HTTParty.get(url)

    Rails.logger.info("Instagram Story Response: #{response.body}")

    return JSON.parse(response.body).with_indifferent_access if response.success?

    handle_error_response(response)
    {}
  rescue StandardError => e
    handle_standard_error(e)
    {}
  end

  def message_identifier
    message[:mid]
  end

  def message_source_id
    @outgoing_echo ? recipient_id : sender_id
  end

  def message_is_unsupported?
    message[:is_unsupported].present? && @messaging[:message][:is_unsupported] == true
  end

  def sender_id
    @messaging[:sender][:id]
  end

  def recipient_id
    @messaging[:recipient][:id]
  end

  def message
    @messaging[:message]
  end

  def contact
    @contact ||= @inbox.contact_inboxes.find_by(source_id: message_source_id)&.contact
  end

  def conversation
    @conversation ||= set_conversation_based_on_inbox_config
  end

  def set_conversation_based_on_inbox_config
    if @inbox.lock_to_single_conversation
      Conversation.where(conversation_params).order(created_at: :desc).first || build_conversation
    else
      find_or_build_for_multiple_conversations
    end
  end

  def find_or_build_for_multiple_conversations
    last_conversation = Conversation.where(conversation_params).where.not(status: :resolved).order(created_at: :desc).first

    return build_conversation if last_conversation.nil?

    last_conversation
  end

  def message_content
    @messaging[:message][:text]
  end

  def story_reply_attributes
    message[:reply_to][:story] if message[:reply_to].present? && message[:reply_to][:story].present?
  end

  def message_reply_attributes
    message[:reply_to][:mid] if message[:reply_to].present? && message[:reply_to][:mid].present?
  end

  def build_message
    return if @outgoing_echo && already_sent_from_chatwoot?
    return if message_content.blank? && all_unsupported_files?

    @message = conversation.messages.create!(direct_message_params)
    save_story_id

    attachments.each do |attachment|
      process_attachment(attachment)
    end
  end

  def save_story_id
    return if story_reply_attributes.blank?

    @message.save_story_info(story_reply_attributes)
  end

  def build_conversation
    @contact_inbox ||= contact.contact_inboxes.find_by!(source_id: message_source_id)

    Conversation.create!(conversation_params.merge(
                           contact_inbox_id: @contact_inbox.id
                         ))
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact.id
    }
  end

  def direct_message_params
    params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: message_type,
      source_id: message_identifier,
      content: message_content,
      sender: @outgoing_echo ? nil : contact,
      content_attributes: {
        in_reply_to_external_id: message_reply_attributes
      }
    }

    params[:content_attributes][:is_unsupported] = true if message_is_unsupported?
    params
  end

  def already_sent_from_chatwoot?
    cw_message = conversation.messages.where(
      source_id: @messaging[:message][:mid]
    ).first

    cw_message.present?
  end

  def all_unsupported_files?
    return if attachments.empty?

    attachments_type = attachments.pluck(:type).uniq.first
    unsupported_file_type?(attachments_type)
  end

  def handle_error(error)
    # TODO: Check if this is the correct way to handle the error
    if error.message.include?('unauthorized')
      @inbox.channel.authorization_error!
      raise
    end
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
    true
  end

  def handle_error_response(response)
    return unless response.code == 404

    @message.attachments.destroy_all
    @message.update(content: I18n.t('conversations.messages.instagram_deleted_story_content'))
  end

  def handle_standard_error(error)
    if error.response&.unauthorized?
      @inbox.channel.authorization_error!
      raise
    end
    Rails.logger.error("Instagram Story Error: #{error.message}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end
end
