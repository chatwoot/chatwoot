class Webhooks::InstagramEventsJob < MutexApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 1.second, attempts: 8

  # @return [Array] We will support further events like reaction or seen in future
  SUPPORTED_EVENTS = [:message, :read].freeze

  def perform(entries)
    @entries = entries

    key = format(::Redis::Alfred::IG_MESSAGE_MUTEX, sender_id: sender_id, ig_account_id: ig_account_id)
    with_lock(key) do
      process_entries(entries)
    end
  end

  # https://developers.facebook.com/docs/messenger-platform/instagram/features/webhook
  def process_entries(entries)
    entries.each do |entry|
      process_single_entry(entry.with_indifferent_access)
    end
  end

  private

  def process_single_entry(entry)
    instagram_account_id = entry[:id]
    @channel = find_channel(instagram_account_id)

    return if @channel.blank?

    process_messages(entry)
  end

  def process_messages(entry)
    messages(entry).each do |messaging|
      Rails.logger.info("Instagram Events Job: messaging: #{messaging}")

      if (event_name = event_name(messaging))
        send(event_name, messaging)
      end
    end
  end

  def ig_account_id
    @entries&.first&.dig(:id)
  end

  def sender_id
    @entries&.dig(0, :messaging, 0, :sender, :id)
  end

  def find_channel(instagram_account_id)
    # There will be chances for the instagram account to be connected to a facebook page,
    # so we need to check for both instagram and facebook page channels
    # priority is for instagram channel which created via instagram login
    channel = Channel::Instagram.find_by(instagram_id: instagram_account_id)
    # If not found, fallback to the facebook page channel
    channel ||= Channel::FacebookPage.find_by(instagram_id: instagram_account_id)

    channel
  end

  def event_name(messaging)
    @event_name ||= SUPPORTED_EVENTS.find { |key| messaging.key?(key) }
  end

  def message(messaging)
    if @channel.is_a?(Channel::Instagram)
      ::Instagram::Direct::MessageText.new(messaging, @channel).perform
    else
      ::Instagram::MessageText.new(messaging, @channel).perform
    end
  end

  def read(messaging)
    # Use a single service to handle read status for both channel types since the params are same
    ::Instagram::ReadStatusService.new(params: messaging, channel: @channel).perform
  end

  def messages(entry)
    (entry[:messaging].presence || entry[:standby] || [])
  end
end

# Actual response from Instagram webhook if the user has sent a message
# [
#   {
#     "time": <timestamp>,
#     "id": <CONNECT_CHANNEL_INSTAGRAM_USER_ID>, // Connect channel Instagram User ID
#     "messaging": [
#       {
#         "sender": {
#           "id": <INSTAGRAM_USER_ID>
#         },
#         "recipient": {
#           "id": <CONNECT_CHANNEL_INSTAGRAM_USER_ID>
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

# Test response from Instagram webhook via developer platform
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
