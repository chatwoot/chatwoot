class Webhooks::InstagramEventsJob < MutexApplicationJob
  queue_as :default
  # This lock is only a short race dampener for first-message conversation creation.
  # ContactInbox creation is already protected by a unique index, but conversation
  # lookup is `find active conversation || create`, so concurrent first messages from
  # the same IG contact can create duplicate conversations.
  #
  # ActiveJob retries are not FIFO, so a longer retry window does not preserve message
  # order. Use deterministic backoff so the final attempt happens after the 3s lock TTL,
  # then process without the lock instead of dropping the webhook.
  retry_on_lock_conflict wait: ->(executions) { executions.seconds }, attempts: 3, on_exhaustion: :process_without_lock

  # @return [Array] We will support further events like reaction or seen in future
  SUPPORTED_EVENTS = [:message, :read, :postback].freeze

  def perform(entries)
    @entries = entries

    key = format(::Redis::Alfred::IG_MESSAGE_MUTEX, sender_id: contact_instagram_id, ig_account_id: ig_account_id)
    # Keep the lock TTL just long enough for the first job to fetch profile data and
    # create the contact/conversation. A longer TTL would add user-visible latency for
    # hot contacts without giving us ordering guarantees.
    with_lock(key, 3.seconds) do
      process_entries(entries)
    end
  end

  def process_without_lock(entries)
    Rails.logger.warn("[#{self.class.name}] Processing without lock after lock retry exhaustion")
    process_entries(entries)
  end

  # https://developers.facebook.com/docs/messenger-platform/instagram/features/webhook
  def process_entries(entries)
    entries.each do |entry|
      process_single_entry(entry.with_indifferent_access)
    end
  end

  private

  def process_single_entry(entry)
    if entry[:changes].present?
      handled = process_changes(entry[:changes], entry)
      return if handled

      process_test_event(entry)
      return
    end

    process_messages(entry)
  end

  # Some webhook events (e.g. postback / quick-reply clicks) arrive via the
  # "changes" array shape instead of the familiar "messaging" array, even in
  # production (not just Meta's test payloads). Route the fields we know
  # about here; anything else falls through to process_test_event as before.
  def process_changes(changes, entry)
    postback_changes = changes.select { |change| change[:field] == 'messaging_postbacks' }
    postback_changes.each { |change| process_postback_change(change, entry) }
    postback_changes.present?
  end

  def process_postback_change(change, entry)
    value = change[:value]&.with_indifferent_access
    return if value.blank?

    recipient_id = value.dig(:recipient, :id)
    channels = matching_channels(recipient_id)
    if channels.empty?
      Rails.logger.info("[IG Webhook] skip postback: no channel for recipient #{recipient_id}")
      return
    end

    messaging = {
      sender: value[:sender],
      recipient: value[:recipient],
      # The "changes" postback payload does not carry its own timestamp; only
      # the containing entry does. Falling back to value[:timestamp] alone
      # left every click on a "changes"-shaped postback with a nil timestamp,
      # making the dedup key identical across genuinely distinct clicks.
      timestamp: value[:timestamp] || entry[:time],
      postback: value[:postback]
    }.with_indifferent_access

    channels.each { |channel| postback(messaging, channel) }
  end

  def process_messages(entry)
    messages(entry).each do |messaging|
      Rails.logger.info("Instagram Events Job Messaging: #{messaging}")

      instagram_id = instagram_id(messaging)
      event_name = event_name(messaging)
      next unless event_name

      # The same Instagram account can be connected via Facebook Page to more
      # than one Chatwoot account, so fan out postback clicks to every
      # matching channel/inbox rather than an arbitrary single one, mirroring
      # FacebookPostbackJob. Other event types keep the single-channel lookup.
      if event_name == :postback
        matching_channels(instagram_id).each { |channel| postback(messaging, channel) }
      else
        channel = find_channel(instagram_id)
        send(event_name, messaging, channel) if channel.present?
      end
    end
  end

  def agent_message_via_echo?(messaging)
    messaging[:message].present? && messaging[:message][:is_echo].present?
  end

  def test_event?(entry)
    entry[:changes].present?
  end

  def process_test_event(entry)
    messaging = extract_messaging_from_test_event(entry)

    Instagram::TestEventService.new(messaging).perform if messaging.present?
  end

  def extract_messaging_from_test_event(entry)
    entry[:changes].first&.dig(:value) if entry[:changes].present?
  end

  def instagram_id(messaging)
    if agent_message_via_echo?(messaging)
      messaging[:sender][:id]
    else
      messaging[:recipient][:id]
    end
  end

  def ig_account_id
    @entries&.first&.dig(:id)
  end

  def contact_instagram_id
    entry = @entries&.first
    return nil unless entry

    # Handle both messaging and standby arrays
    messaging = (entry[:messaging].presence || entry[:standby] || []).first
    return contact_instagram_id_from_changes(entry) unless messaging

    # For echo messages (outgoing from our account), use recipient's ID (the contact)
    # For incoming messages (from contact), use sender's ID (the contact)
    if messaging.dig(:message, :is_echo)
      messaging.dig(:recipient, :id)
    else
      messaging.dig(:sender, :id)
    end
  end

  # The "changes" postback shape has no messaging/standby array, so the lock
  # key would otherwise fall back to nil and every changes-shaped postback
  # for the account would contend on one account-wide lock instead of a
  # sender-specific one.
  def contact_instagram_id_from_changes(entry)
    entry[:changes]&.first&.dig(:value, :sender, :id)
  end

  def sender_id
    @entries&.dig(0, :messaging, 0, :sender, :id)
  end

  def find_channel(instagram_id)
    # There will be chances for the instagram account to be connected to a facebook page,
    # so we need to check for both instagram and facebook page channels
    # priority is for instagram channel which created via instagram login
    channel = Channel::Instagram.find_by(instagram_id: instagram_id)
    # If not found, fallback to the facebook page channel
    channel ||= Channel::FacebookPage.find_by(instagram_id: instagram_id)

    channel
  end

  # Unlike Channel::Instagram (unique per Instagram business login connection),
  # the same Facebook Page can be connected to more than one Chatwoot account,
  # so callers that must reach every affected inbox (e.g. postback fan-out)
  # need every matching channel, not just the first one found.
  def matching_channels(instagram_id)
    return [] if instagram_id.blank?

    Channel::Instagram.where(instagram_id: instagram_id).to_a +
      Channel::FacebookPage.where(instagram_id: instagram_id).to_a
  end

  def event_name(messaging)
    SUPPORTED_EVENTS.find { |key| messaging.key?(key) }
  end

  def message(messaging, channel)
    if channel.is_a?(Channel::Instagram)
      ::Instagram::MessageText.new(messaging, channel).perform
    else
      ::Instagram::Messenger::MessageText.new(messaging, channel).perform
    end
  end

  def read(messaging, channel)
    # Use a single service to handle read status for both channel types since the params are same
    ::Instagram::ReadStatusService.new(params: messaging, channel: channel).perform
  end

  # Quick reply / interactive button clicks
  # https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/messaging_postbacks
  def postback(messaging, channel)
    if channel.is_a?(Channel::Instagram)
      ::Instagram::PostbackEvent.new(messaging, channel).perform
    else
      ::Instagram::Messenger::PostbackEvent.new(messaging, channel).perform
    end
  end

  def messages(entry)
    (entry[:messaging].presence || entry[:standby] || [])
  end
end

# Actual response from Instagram webhook (both via Facebook page and Instagram direct)
# [
#   {
#     "time": <timestamp>,
#     "id": <INSTAGRAM_USER_ID>,
#     "messaging": [
#       {
#         "sender": {
#           "id": <INSTAGRAM_USER_ID>
#         },
#         "recipient": {
#           "id": <INSTAGRAM_USER_ID>
#         },
#         "timestamp": <timestamp>,
#         "message": {
#           "mid": <MESSAGE_ID>,
#           "text": <MESSAGE_TEXT>
#         }
#       }
#     ]
#   }
# ]

# Instagram's webhook via Instagram direct testing quirk: Test payloads vs Actual payloads
# When testing in Facebook's developer dashboard, you'll get a Page-style
# payload with a "changes" object. But don't be fooled! Real Instagram DMs
# arrive in the familiar Messenger format with a "messaging" array.
# This apparent inconsistency is actually by design - Instagram's webhooks
# use different formats for testing vs production to maintain compatibility
# with both Instagram Direct and Facebook Page integrations.
# See: https://developers.facebook.com/docs/instagram-platform/webhooks#event-notifications

# Test response from via Instagram direct
# [
#   {
#     "id": "0",
#     "time": <timestamp>,
#     "changes": [
#       {
#         "field": "messages",
#         "value": {
#           "sender": {
#             "id": "12334"
#           },
#           "recipient": {
#             "id": "23245"
#           },
#           "timestamp": "1527459824",
#           "message": {
#             "mid": "random_mid",
#             "text": "random_text"
#           }
#         }
#       }
#     ]
#   }
# ]

# Test response via Facebook page
# [
#   {
#     "time": <timestamp>,,
#     "id": "0",
#     "messaging": [
#       {
#         "sender": {
#           "id": "12334"
#         },
#         "recipient": {
#           "id": "23245"
#         },
#         "timestamp": <timestamp>,
#         "message": {
#             "mid": "random_mid",
#             "text": "random_text"
#         }
#       }
#     ]
#   }
# ]
