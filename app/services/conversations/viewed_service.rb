# frozen_string_literal: true

class Conversations::ViewedService
  include Events::Types

  THROTTLE_WINDOW = 60.seconds

  def initialize(conversation:, user:)
    @conversation = conversation
    @user = user
  end

  def perform
    return if throttled?

    Rails.cache.write(cache_key, true, expires_in: THROTTLE_WINDOW)
    dispatch_event
  end

  private

  def dispatch_event
    Rails.configuration.dispatcher.dispatch(
      CONVERSATION_VIEWED,
      Time.zone.now,
      conversation: @conversation,
      viewed_by: @user
    )
  end

  def throttled?
    Rails.cache.read(cache_key).present?
  end

  def cache_key
    "conversation_viewed/#{@conversation.id}/#{@user&.id}"
  end
end
