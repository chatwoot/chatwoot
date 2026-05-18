json.data do
  json.partial! 'chatwoot_kanban/api/v1/checklist_items/checklist_item', item: @item
end
