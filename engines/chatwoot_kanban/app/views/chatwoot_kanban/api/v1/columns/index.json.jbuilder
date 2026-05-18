json.data do
  json.array! @columns, partial: 'chatwoot_kanban/api/v1/columns/column', as: :column
end
