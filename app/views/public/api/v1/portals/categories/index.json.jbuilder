json.payload do
  json.array! @categories, partial: 'public/api/v1/models/category.json.jbuilder', as: :category
end
