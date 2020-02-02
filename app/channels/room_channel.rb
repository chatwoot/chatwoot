class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_from params[:pubsub_token]
    ::OnlineStatusTracker.add_subscription(params[:pubsub_token])
  end

  def unsubscribed
    ::OnlineStatusTracker.remove_subscription(params[:pubsub_token])
  end
end
