json.data do
  json.array! @items, partial: 'chatwoot_kanban/api/v1/checklist_items/checklist_item', as: :item
end
