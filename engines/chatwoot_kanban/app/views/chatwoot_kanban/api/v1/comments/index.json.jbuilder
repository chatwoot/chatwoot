json.data do
  json.array! @comments, partial: 'chatwoot_kanban/api/v1/comments/comment', as: :comment
end
