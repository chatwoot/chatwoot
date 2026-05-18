json.data do
  json.partial! 'chatwoot_kanban/api/v1/columns/column', column: @column
end
