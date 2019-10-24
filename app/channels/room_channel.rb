class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_from params[:pubsub_token]
  end
end
