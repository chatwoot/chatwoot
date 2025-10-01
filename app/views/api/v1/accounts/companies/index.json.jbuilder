json.payload do
  json.array! @companies do |company|
    json.partial! 'company', company: company
  end
end
