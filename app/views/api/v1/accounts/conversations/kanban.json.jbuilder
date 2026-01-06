json.data do
  %w[open pending snoozed resolved].each do |status|
    json.set! status do
      json.conversations do
        json.array! @kanban_data[status][:conversations] do |conversation|
          json.partial! 'api/v1/conversations/partials/conversation', formats: [:json], conversation: conversation
        end
      end
      json.meta do
        json.count @kanban_data[status][:count]
        json.has_more @kanban_data[status][:has_more]
      end
    end
  end
end
