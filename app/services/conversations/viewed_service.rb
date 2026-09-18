# frozen_string_literal: true

class Conversations::ViewedService
  include Events::Types

  THROTTLE_WINDOW = 60.seconds

  def initialize(conversation:, user:)
    @conversation = conversation
    @user = user
  end

  def perform
    return unless claim_throttle_key

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

  def claim_throttle_key
    Redis::Alfred.set(throttle_key, true, nx: true, ex: THROTTLE_WINDOW.to_i)
  end

  def throttle_key
    "conversation_viewed/#{@conversation.id}/#{@user&.id}"
  end
end
