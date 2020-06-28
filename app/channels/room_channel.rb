class RoomChannel < ApplicationCable::Channel
  def subscribed
    update_subscription
  end

  def update_presence
    update_subscription
  end

  private

  def update_subscription
    stream_from params[:pubsub_token]
    ::OnlineStatusTracker.update_presence(params[:pubsub_token])
  end
end
