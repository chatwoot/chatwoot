json.data do
  json.partial! 'chatwoot_kanban/api/v1/cards/card', card: @card
end
