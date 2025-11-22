json.meta do
  json.count @payment_links_count
  json.current_page @current_page
end

json.payload do
  json.array! @payment_links do |payment_link|
    json.partial! 'api/v1/models/payment_link', formats: [:json], resource: payment_link
  end
end
