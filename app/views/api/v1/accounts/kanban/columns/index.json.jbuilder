json.array! @columns do |column|
  json.partial! 'api/v1/accounts/kanban/columns/column', column: column
  json.cards column.cards do |card|
    json.partial! 'api/v1/accounts/kanban/cards/card', card: card
  end
end
