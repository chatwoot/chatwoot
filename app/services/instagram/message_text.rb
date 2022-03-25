class Instagram::MessageText < Instagram::WebhooksBaseService
  include HTTParty

  attr_reader :messaging

  base_uri 'https://graph.facebook.com/v11.0/'

  def initialize(messaging)
    super()
    @messaging = messaging
  end

  def perform
    instagram_id, contact_id = if agent_message_via_echo?
                                 [@messaging[:sender][:id], @messaging[:recipient][:id]]
                               else
                                 [@messaging[:recipient][:id], @messaging[:sender][:id]]
                               end
    inbox_channel(instagram_id)
    # person can connect the channel and then delete the inbox
    return if @inbox.blank?

    return unsend_message if message_is_deleted?

    ensure_contact(contact_id)

    create_message
  end

  private

  def ensure_contact(ig_scope_id)
    begin
      k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?
      result = k.get_object(ig_scope_id) || {}
    rescue Koala::Facebook::AuthenticationError
      @inbox.channel.authorization_error!
      raise
    rescue StandardError => e
      result = {}
      Sentry.capture_exception(e)
    end

    find_or_create_contact(result)
  end

  def agent_message_via_echo?
    @messaging[:message][:is_echo].present?
  end

  def message_is_deleted?
    @messaging[:message][:is_deleted].present?
  end

  def unsend_message
    message_to_delete = @inbox.messages.find_by(
      source_id: @messaging[:message][:mid]
    )
    return if message_to_delete.blank?

    message_to_delete.update!(content: I18n.t('conversations.messages.deleted'), deleted: true)
  end

  def create_message
    Messages::Instagram::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end
end
