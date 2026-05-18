json.data do
  json.array! @boards, partial: 'chatwoot_kanban/api/v1/boards/board', as: :board
end
json.meta do
  json.total @boards.size
end
