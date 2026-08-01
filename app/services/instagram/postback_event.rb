# Service to handle Instagram Ads Quick Reply postback events
# These events are sent when a user clicks on a Quick Reply button in an Instagram Ad
# https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/messaging_postbacks
class Instagram::PostbackEvent < Instagram::WebhooksBaseService
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

  # if contact was present before find out contact_inbox to create message
  def contacts_first_message?(ig_scope_id)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: ig_scope_id).last
    @contact_inbox.blank? && @inbox.channel.instagram_id.present?
  end

  def ensure_contact(ig_scope_id)
    result = fetch_instagram_user(ig_scope_id)
    find_or_create_contact(result) if result.present?
  end

  def fetch_instagram_user(ig_scope_id)
    fields = 'name,username,profile_pic,follower_count,is_user_follow_business,is_business_follow_user,is_verified_user'
    url = "#{base_uri}/#{ig_scope_id}?fields=#{fields}&access_token=#{@inbox.channel.access_token}"

    response = HTTParty.get(url)

    return process_successful_response(response) if response.success?

    handle_error_response(response, ig_scope_id) || unknown_user(ig_scope_id)
  end

  def process_successful_response(response)
    result = JSON.parse(response.body).with_indifferent_access
    {
      'name' => result['name'],
      'username' => result['username'],
      'profile_pic' => result['profile_pic'],
      'id' => result['id'],
      'follower_count' => result['follower_count'],
      'is_user_follow_business' => result['is_user_follow_business'],
      'is_business_follow_user' => result['is_business_follow_user'],
      'is_verified_user' => result['is_verified_user']
    }.with_indifferent_access
  end

  def handle_error_response(response, ig_scope_id)
    parsed_response = response.parsed_response
    parsed_response = JSON.parse(parsed_response) if parsed_response.is_a?(String)
    error_code = parsed_response.dig('error', 'code')
    error_message = parsed_response.dig('error', 'message')

    # Access token has expired or become invalid
    channel.authorization_error! if error_code == 190

    # User consent error - common for ads where user hasn't messaged before
    return unknown_user(ig_scope_id) if error_code == 230

    # No matching Instagram user
    return unknown_user(ig_scope_id) if error_code == 9010

    Rails.logger.warn("[InstagramPostbackUserFetchError]: account_id #{@inbox.account_id} inbox_id #{@inbox.id}")
    Rails.logger.warn("[InstagramPostbackUserFetchError]: #{error_message} #{error_code}")

    nil
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

  def base_uri
    "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"
  end
end
