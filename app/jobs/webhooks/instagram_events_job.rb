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

  # @see https://developers.facebook.com/docs/messenger-platform/instagram/features/webhook
  def process_entries(entries)
    entries.each do |entry|
      entry = entry.with_indifferent_access
      instagram_account_id = entry[:id]

      # Find the appropriate channel
      @channel = find_channel(instagram_account_id)

      # Skip processing if no channel found
      next if @channel.blank?

      messages(entry).each do |messaging|
        Rails.logger.info("Instagram Events Job: messaging: #{messaging}")
        send(@event_name, messaging) if event_name(messaging)
      end
    end
  end

  private

  def ig_account_id
    @entries&.first&.dig(:id)
  end

  def sender_id
    @entries&.dig(0, :messaging, 0, :sender, :id)
  end

  def find_channel(instagram_account_id)
    # First try to find Instagram direct channel
    channel = Channel::Instagram.find_by(instagram_id: instagram_account_id)
    # If not found, fallback to Facebook page channel
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
    if @channel.is_a?(Channel::Instagram)
      ::Instagram::Direct::ReadStatusService.new(params: messaging, channel: @channel).perform
    else
      ::Instagram::ReadStatusService.new(params: messaging, channel: @channel).perform
    end
  end

  def messages(entry)
    (entry[:messaging].presence || entry[:standby] || [])
  end
end

# Sample response
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
