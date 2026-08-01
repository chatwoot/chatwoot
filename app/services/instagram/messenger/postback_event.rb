# Service to handle Instagram Ads Quick Reply postback events via Facebook Messenger API
# Used when Instagram is connected via a Facebook Page
class Instagram::Messenger::PostbackEvent < Instagram::WebhooksBaseService
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
      Rails.logger.info("Skipping postback processing as reauthorization is required for inbox #{@inbox.id}")
      return
    end

    ensure_contact(contact_id) if contacts_first_message?(contact_id)

    create_message
  end

  private

  def instagram_and_contact_ids
    # Postback events are always incoming from the user
    [@messaging[:recipient][:id], @messaging[:sender][:id]]
  end

  def contacts_first_message?(ig_scope_id)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: ig_scope_id).last
    @contact_inbox.blank? && (@inbox.channel.instagram_id.present? || @inbox.channel.page_id.present?)
  end

  def ensure_contact(ig_scope_id)
    result = fetch_instagram_user(ig_scope_id)
    find_or_create_contact(result) if result.present?
  end

  def fetch_instagram_user(ig_scope_id)
    k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?
    k.get_object(ig_scope_id) || {}
  rescue Koala::Facebook::AuthenticationError => e
    handle_authentication_error(e)
    unknown_user(ig_scope_id)
  rescue StandardError, Koala::Facebook::ClientError => e
    handle_client_error(e, ig_scope_id)
  end

  def handle_authentication_error(error)
    @inbox.channel.authorization_error!
    Rails.logger.warn("Authorization error for account #{@inbox.account_id} for inbox #{@inbox.id}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end

  def handle_client_error(error, ig_scope_id)
    # Handle error code 230: User consent is required - common for ads
    return unknown_user(ig_scope_id) if error.message.include?('230')

    # Handle error code 9010: No matching Instagram user
    return unknown_user(ig_scope_id) if error.message.include?('9010')

    Rails.logger.warn("[FacebookPostbackUserFetchError]: account_id #{@inbox.account_id} inbox_id #{@inbox.id}")
    Rails.logger.warn("[FacebookPostbackUserFetchError]: #{error.message}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception

    unknown_user(ig_scope_id)
  end

  def unknown_user(ig_scope_id)
    {
      'name' => "Instagram User (#{ig_scope_id})",
      'id' => ig_scope_id
    }.with_indifferent_access
  end

  def create_message
    return unless @contact_inbox

    Messages::Instagram::PostbackBuilder.new(@messaging, @inbox).perform
  end
end
