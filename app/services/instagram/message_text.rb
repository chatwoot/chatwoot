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

  def create_message
    Messages::Instagram::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end
end
