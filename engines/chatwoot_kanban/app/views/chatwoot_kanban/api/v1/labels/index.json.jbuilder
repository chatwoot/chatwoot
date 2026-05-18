json.data do
  json.array! @labels, partial: 'chatwoot_kanban/api/v1/labels/label', as: :label
end
