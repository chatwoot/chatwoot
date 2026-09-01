# ref : https://developers.line.biz/en/docs/messaging-api/receiving-messages/#webhook-event-types
# https://developers.line.biz/en/reference/messaging-api/#message-event

class Line::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    # probably test events
    return if params[:events].blank?

    parse_events
  end

  private

  def parse_events
    grouped_events = params[:events].group_by do |event|
      event.dig('source', 'userId')
    end
    grouped_events.each_value do |events|
      Line::MessageCreator.perform_later(@inbox, events)
    end
  end
end
