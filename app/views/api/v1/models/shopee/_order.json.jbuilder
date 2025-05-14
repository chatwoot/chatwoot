json.shopId order.shop_id
json.number order.number
json.buyerUsername order.buyer_username
json.buyerUserId order.buyer_user_id
json.totalAmount order.total_amount
json.status order.status
json.cod order.cod
json.meta order.meta
json.order_items do
  json.array! order.order_items do |item|
    json.code item.code
    json.itemCode item.item_code
    json.itemName item.item_name
    json.itemSku item.item_sku
    json.price item.price
    json.meta item.meta
  end
end
