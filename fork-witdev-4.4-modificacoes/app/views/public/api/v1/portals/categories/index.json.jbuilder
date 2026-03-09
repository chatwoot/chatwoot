json.payload do
  json.array! @categories, partial: 'public/api/v1/models/category', formats: [:json], as: :category
end
