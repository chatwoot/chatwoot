class Instagram::BaseMessageText < Instagram::WebhooksBaseService
  attr_reader :messaging

  def initialize(messaging, channel)
    @messaging = messaging
    super(channel)
  end

  def perform
    connected_instagram_id, contact_id = instagram_and_contact_ids
    inbox_channel(connected_instagram_id)

    return if @inbox.blank?

    if @inbox.channel.reauthorization_required?
      Rails.logger.info("Skipping message processing as reauthorization is required for inbox #{@inbox.id}")
      return
    end

    return unsend_message if message_is_deleted?

    # This ensures contact persists even if message processing fails
    if contacts_first_message?(contact_id)
      Rails.logger.info "[Instagram] Creating contact outside transaction - Source:#{contact_id}, Account:#{@inbox.account_id}"
      ensure_contact_handler(contact_id)
    end

    # Create message separately - failures here won't affect contact
    create_message_handler
  end

  private

  def instagram_and_contact_ids
    if agent_message_via_echo?
      [@messaging[:sender][:id], @messaging[:recipient][:id]]
    else
      [@messaging[:recipient][:id], @messaging[:sender][:id]]
    end
  end

  def agent_message_via_echo?
    @messaging[:message][:is_echo].present?
  end

  def message_is_deleted?
    @messaging[:message][:is_deleted].present?
  end

  # if contact was present before find out contact_inbox to create message
  def contacts_first_message?(ig_scope_id)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: ig_scope_id).last
    @contact_inbox.blank? && @inbox.channel.instagram_id.present?
  end

  def ensure_contact_handler(contact_id)
    ensure_contact(contact_id)
  rescue StandardError => e
    Rails.logger.error "[Instagram] Contact creation failed - Source:#{contact_id}, Error: #{e.class}: #{e.message}"
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    # Don't re-raise - let message processing continue even if contact creation fails
  end

  def create_message_handler
    return unless @contact_inbox

    begin
      create_message
    rescue StandardError => e
      Rails.logger.error "[Instagram] Message creation failed - ContactInbox:#{@contact_inbox.id}, Error: #{e.class}: #{e.message}"
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    end
  end

  def unsend_message
    message_to_delete = @inbox.messages.find_by(
      source_id: @messaging[:message][:mid]
    )
    return if message_to_delete.blank?

    message_to_delete.attachments.destroy_all
    message_to_delete.update!(content: I18n.t('conversations.messages.deleted'), deleted: true)
  end

  # Methods to be implemented by subclasses
  def ensure_contact(contact_id)
    raise NotImplementedError, "#{self.class} must implement #ensure_contact"
  end

  def create_message
    raise NotImplementedError, "#{self.class} must implement #create_message"
  end
end
