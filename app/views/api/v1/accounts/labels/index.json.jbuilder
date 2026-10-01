json.payload do
  json.array! @labels do |label|
    json.id label.id
    json.title label.title
    json.description label.description
    json.color label.color
    json.show_on_sidebar label.show_on_sidebar
    json.parent_id label.parent_id
    json.depth label.depth
    json.children_count label.children_count
    json.children label.children do |child|
      json.id child.id
      json.title child.title
      json.description child.description
      json.color child.color
      json.show_on_sidebar child.show_on_sidebar
      json.parent_id child.parent_id
      json.depth child.depth
      json.children_count child.children_count
    end
  end
end
