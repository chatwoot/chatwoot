json.meta do
  json.count @tickets.total_count
  json.current_page @tickets.current_page
end

json.payload do
  json.array! @tickets do |ticket|
    json.partial! 'api/v1/models/ticket', formats: [:json], resource: ticket

    # The list view shows who owns the case; the conversation's assignee is the
    # answer, and the controller already preloads it.
    assignee = ticket.conversation.assignee
    if assignee.present?
      json.assignee do
        json.id assignee.id
        json.name assignee.name
        json.thumbnail assignee.avatar_url
      end
    else
      json.assignee nil
    end
  end
end
