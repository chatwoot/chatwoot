json.payload do
  json.array! @labels do |label|
    json.id label.id
    json.title label.title
    json.description label.description
    json.color label.color
    json.show_on_sidebar label.show_on_sidebar
    json.pinned_by_current_user current_user.label_pinned?(label.id)
  end
end
