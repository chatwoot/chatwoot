class Webhooks::Instagram
  include HTTParty

  base_uri 'https://graph.facebook.com/v11.0/me'

  # @return [Array] We will support further events like reaction or seen in future
  SUPPORTED_EVENTS = [:message].freeze

  def initialize(entries)
    @entries = entries
  end

  # @see https://developers.facebook.com/docs/messenger-platform/instagram/features/webhook
  def consume
    if @entries[0].key?(:changes)
      Rails.logger.info('Probably Test data.')

      return
    end

    @entries.each do |entry|
      entry[:messaging].each do |messaging|
        send(@event_name, messaging) if event_name(messaging)
      end
    end
  end

  private

  def event_name(messaging)
    @event_name ||= SUPPORTED_EVENTS.find { |key| messaging.key?(key) }
  end

  def message(messaging)
    ::Instagram::MessageText.new(messaging).perform
  end
end
