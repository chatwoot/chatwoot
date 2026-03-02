json.meta do
  json.count @orders_count
  json.current_page @current_page
end

json.payload do
  json.array! @orders do |order|
    json.partial! 'api/v1/models/order', formats: [:json], resource: order
  end
end
