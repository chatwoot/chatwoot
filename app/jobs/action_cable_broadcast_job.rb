class ActionCableBroadcastJob < ApplicationJob
  queue_as :default

  def perform(members, event_name, data)
    members.each do |member|
      ActionCable.server.broadcast(member, { event: event_name, data: data })
    end
  end
end
