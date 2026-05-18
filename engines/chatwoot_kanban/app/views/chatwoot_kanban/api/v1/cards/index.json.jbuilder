json.data do
  json.array! @cards, partial: 'chatwoot_kanban/api/v1/cards/card', as: :card
end
