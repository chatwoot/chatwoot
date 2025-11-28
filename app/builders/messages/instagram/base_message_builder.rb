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
    contact_id = contact.id
    inbox_id = @inbox.id
    account_id = @inbox.account_id

    # Find existing conversation first
    template_dm_conversation = Conversation.where(
      contact_id: contact_id,
      inbox_id: inbox_id,
      account_id: account_id
    ).where("conversations.additional_attributes->>'type' = ?", 'instagram_dm').last

    if template_dm_conversation
      Rails.logger.info "Found existing template_dm conversation #{template_dm_conversation.id} for contact #{contact_id} in inbox #{inbox_id}"
      @conversation = template_dm_conversation
    else
      Rails.logger.info "No existing template_dm conversation found, creating a new one for contact #{contact_id} in inbox #{inbox_id}"
      @conversation = build_conversation
    end

    # Stop if this message was already processed
    return if message_already_exists?

    # Skip if no content and all attachments unsupported
    return if message_content.blank? && all_unsupported_files?

    # Create the message
    @message = @conversation.messages.create!(message_params)
    save_story_id

    # Update conversation to mark as instagram_dm if not already set
    additional_attributes = @conversation.additional_attributes || {}
    unless additional_attributes['type'] == 'instagram_dm'
      additional_attributes['type'] = 'instagram_dm'
      @conversation.update!(additional_attributes: additional_attributes)
    end

    # Handle attachments
    attachments.each do |attachment|
      process_attachment(attachment)
    end

    ensure_story_mention_content
  end

  def save_story_id
    return if story_reply_attributes.blank?

    story_payload = {
      'id' => story_reply_attributes['id'],
      'url' => story_reply_attributes['url'],
      'story_sender' => story_sender_label
    }.compact

    @message.save_story_info(story_payload)
    ensure_story_attachment(story_payload['url'])

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
      },
      additional_attributes: {'delivery_status': 'sent'}
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

  def ensure_story_mention_content
    return unless @message.present?
    return unless @message.content_attributes[:image_type] == 'story_mention'

    Rails.logger.info(
      "[InstagramStoryMentionFallback] message_id=#{@message.id} content missing. attributes=#{@message.content_attributes}"
    )

    if @message.outgoing?
      reply_content = I18n.t(
        'conversations.messages.instagram_story_reply_content',
        username: story_reply_username
      )
      @message.update!(content: reply_content) unless @message.content == reply_content
    elsif @message.content.blank?
      @message.update!(content: I18n.t('conversations.messages.instagram_story_content', story_sender: story_sender_label))
    end
  end

  def story_reply_username
    contact_name = contact&.additional_attributes&.dig('social_instagram_user_name') ||
                   contact&.additional_attributes&.dig('social_profiles', 'instagram') ||
                   contact&.name ||
                   contact&.identifier
    contact_name.presence || I18n.t('conversations.messages.instagram_story_unknown_sender')
  end

  def story_sender_label
    story_sender_attr = @message.content_attributes[:story_sender]
    raw_sender = story_sender_attr.to_s.strip
    contact_name = contact&.name.presence || contact&.identifier.presence

    if raw_sender.blank? || raw_sender =~ /\A\d+\z/
      contact_name.presence || I18n.t('conversations.messages.instagram_story_unknown_sender')
    else
      raw_sender
    end
  end

  def ensure_story_attachment(story_url)
    return if story_url.blank?
    return if @message.attachments.exists?

    @message.attachments.create!(
      account_id: @message.account_id,
      file_type: :story_mention,
      external_url: story_url
    )
  end

  def process_attachment(attachment)
    super(attachment)
    ensure_story_mention_content if attachment['type'].to_s == 'story_mention'
  end

  # Abstract methods to be implemented by subclasses
  def get_story_object_from_source_id(source_id)
    raise NotImplementedError
  end
end
