json.id @account.id
json.plan_name @billing_subscription.present? ? @billing_subscription.billing_product_price.billing_product.product_name.capitalize : 'Trial'
json.agent_count @account.account_users.count
json.available_product_prices do 
  json.array! @available_product_prices.each do |product_price|
    json.id product_price.id
    json.name product_price.billing_product.product_name
    json.display_name "#{product_price.billing_product.product_name} - #{(product_price.unit_amount.to_i/100).to_s} $ / agent / month"
    json.unit (product_price.unit_amount.to_i/100).to_s 
  end
end
