json.payload do
  json.array! @products do |product|
    json.partial! 'api/v1/accounts/products/product', product: product
  end
end
