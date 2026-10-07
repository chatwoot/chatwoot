json.payload do
  json.array! @suggestions do |suggestion|
    json.partial! 'api/v1/models/captain/faq_suggestion', formats: [:json], resource: suggestion
  end
end

json.meta do
  json.total_count @suggestions_count
  json.page @current_page
end
