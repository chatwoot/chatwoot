class Messages::Instagram::BaseMessageBuilder < Messages::Messenger::MessageBuilder
  attr_reader :messaging

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
      find_conversation_scope.order(created_at: :desc).first || build_conversation
    else
      find_or_build_for_multiple_conversations
    end
  end

  def find_conversation_scope
    Conversation.where(conversation_params)
  end

  def find_or_build_for_multiple_conversations
    last_conversation = find_conversation_scope.where.not(status: :resolved).order(created_at: :desc).first
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
    # Duplicate webhook events may be sent for the same message
    # when a user is connected to the Instagram account through both Messenger and Instagram login.
    # There is chance for echo events to be sent for the same message.
    # Therefore, we need to check if the message already exists before creating it.
    return if message_already_exists?

    return if message_content.blank? && all_unsupported_files?

    @message = conversation.messages.create!(message_params)
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
                           contact_inbox_id: @contact_inbox.id,
                           additional_attributes: additional_conversation_attributes
                         ))
  end

  def additional_conversation_attributes
    {}
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact.id
    }
  end

  def message_params
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

  def message_already_exists?
    find_message_by_source_id(@messaging[:message][:mid]).present?
  end

  def find_message_by_source_id(source_id)
    return unless source_id

    @message = Message.find_by(source_id: source_id)
  end

  def all_unsupported_files?
    return if attachments.empty?

    attachments_type = attachments.pluck(:type).uniq.first
    unsupported_file_type?(attachments_type)
  end

  def handle_error(error)
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
    true
  end

  # Abstract methods to be implemented by subclasses
  def get_story_object_from_source_id(source_id)
    raise NotImplementedError
  end
end
