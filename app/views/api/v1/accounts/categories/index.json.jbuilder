json.payload do
  json.array! @categories, partial: 'category', as: :category
end
