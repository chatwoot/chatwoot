class Webhooks::InstagramEventsJob < MutexApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 2.seconds, attempts: 8

  include HTTParty

  base_uri 'https://graph.facebook.com/v11.0/me'

  # @return [Array] We will support further events like reaction or seen in future
  SUPPORTED_EVENTS = [:message, :postback, :read].freeze

  def perform(entries)
    @entries = entries

    key = format(::Redis::Alfred::IG_MESSAGE_MUTEX, sender_id: sender_id, ig_account_id: ig_account_id)
    with_lock(key, 30.seconds) do
      process_entries(entries)
    end
  end

  # @see https://developers.facebook.com/docs/messenger-platform/instagram/features/webhook
  def process_entries(entries)
    entries.each do |entry|
      entry = entry.to_unsafe_h if entry.respond_to?(:to_unsafe_h)
      entry = entry.with_indifferent_access
      begin
        messages(entry).each do |messaging|
          if event_name(messaging)
            Rails.logger.info("Processing Instagram message for entry ID: #{entry[:id]}")
            send(@event_name, messaging)
          end
        end
      rescue StandardError => e
        Rails.logger.error("Error processing Instagram entry: #{entry.inspect}")
        Rails.logger.error(e)
      end
    end
  end

  private

  def ig_account_id
    @entries&.first&.dig(:id)
  end

  def sender_id
    messaging = @entries&.dig(0, :messaging, 0) || @entries&.dig(0, :standby, 0)
    messaging&.dig(:sender, :id)
  end

  def event_name(messaging)
    @event_name ||= SUPPORTED_EVENTS.find { |key| messaging.key?(key) }
  end

  def message(messaging)
    ::Instagram::MessageText.new(messaging).perform
  end

  def postback(messaging)
    ::Instagram::Postback.new(messaging).perform
  end

  def read(messaging)
    ::Instagram::ReadStatusService.new(params: messaging).perform
  end

  def messages(entry)
    (entry[:messaging].presence || entry[:standby] || [])
  end
end
