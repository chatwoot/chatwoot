json.payload do
  json.array! @orders do |order|
    json.partial! 'api/v1/models/order', formats: [:json], resource: order
  end
end
