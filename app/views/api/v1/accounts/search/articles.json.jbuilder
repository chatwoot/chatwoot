json.payload do
  json.articles do
    json.array! @result[:articles] do |article|
      json.partial! 'article', formats: [:json], article: article
    end
  end
end