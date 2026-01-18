json.meta do
  json.count @carts_count
  json.current_page @current_page
end

json.payload do
  json.array! @carts do |cart|
    json.partial! 'api/v1/models/cart', formats: [:json], resource: cart
  end
end
