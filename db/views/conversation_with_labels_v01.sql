SELECT
  conversations.*,
  array_agg(tags.name) as labels_array
FROM
  conversations
  LEFT JOIN taggings ON taggings.taggable_id = conversations.id
  AND taggings.taggable_type = 'Conversation'
  AND taggings.context = 'labels'
  LEFT JOIN tags ON tags.id = taggings.tag_id
GROUP BY
  conversations.id;