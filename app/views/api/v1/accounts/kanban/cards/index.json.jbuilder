json.array! @cards do |card|
  json.partial! 'api/v1/accounts/kanban/cards/card', card: card
end
