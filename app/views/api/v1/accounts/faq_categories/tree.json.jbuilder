def render_category_tree(json, category)
  json.id category.id
  json.name category.name
  json.description category.description
  json.parent_id category.parent_id
  json.position category.position
  json.is_visible category.is_visible
  json.faq_items_count category.faq_items.size
  json.created_at category.created_at
  json.updated_at category.updated_at
  json.children category.children.ordered do |child|
    render_category_tree(json, child)
  end
end

json.data @faq_categories do |category|
  render_category_tree(json, category)
end

json.meta do
  json.current_page @current_page
  json.total_pages @total_pages
  json.total_count @total_count
  json.per_page 50
end
