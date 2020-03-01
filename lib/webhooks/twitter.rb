# frozen_string_literal: true

class Webhooks::Twitter
  SUPPORTED_EVENTS = [:direct_message_events, :tweet_create_events].freeze

  attr_accessor :params, :account

  def initialize(params)
    @params = params
  end

  def consume
    send(event_name) if event_name
  end

  private

  def event_name
    @event_name ||= SUPPORTED_EVENTS.find { |key| @params.key?(key.to_s) }
  end

  def direct_message_events
    ::Twitter::DirectMessageParserService.new(payload: @params).perform
  end

  def tweet_create_events
    ::Twitter::TweetParserService.new(payload: @params).perform
  end
end
