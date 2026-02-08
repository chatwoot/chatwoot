json.payload do
  json.array! @categories, partial: 'category', as: :category
end

json.meta do
  json.current_page @current_page
  json.categories_count @categories.size
end
