class PusherCallJob < ApplicationJob
  queue_as :default

  def perform(member, event_name, data)
    ActionCable.server.broadcast(member, event: event_name, data: data)
  end
end
