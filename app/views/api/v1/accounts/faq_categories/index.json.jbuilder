json.data @faq_categories do |category|
  json.id category.id
  json.name category.name
  json.description category.description
  json.parent_id category.parent_id
  json.position category.position
  json.is_visible category.is_visible
  json.created_at category.created_at
  json.updated_at category.updated_at
  json.faq_items_count category.faq_items.count

  json.children category.children.ordered do |child|
    json.id child.id
    json.name child.name
    json.description child.description
    json.parent_id child.parent_id
    json.position child.position
    json.is_visible child.is_visible
    json.faq_items_count child.faq_items.count
  end
end
