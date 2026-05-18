json.data do
  json.partial! 'chatwoot_kanban/api/v1/labels/label', label: @label
end
