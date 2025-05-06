json.payload do
  json.array! @products do |product|
    json.partial! 'api/v1/models/shopee/product', product: product
  end
end
