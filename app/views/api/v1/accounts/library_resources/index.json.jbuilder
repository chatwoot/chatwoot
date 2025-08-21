json.payload do
  json.array! @library_resources, partial: 'library_resource', as: :library_resource
end

json.meta do
  json.count @library_resources.size
  json.current_page @current_page
end