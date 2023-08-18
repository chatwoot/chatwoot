json.id @account.id
if @billing_subscription&.billing_product_price.present?
  json.plan_name @billing_subscription.billing_product_price.billing_product.product_name.capitalize
  json.plan_id @billing_subscription.billing_product_price.id
  json.allowed_no_agents @billing_subscription.billing_product_price.limits['agents']
  json.chat_history @billing_subscription.billing_product_price.limits['history']
  json.plan_expiry_date @billing_subscription.current_period_end

end
json.available_product_prices do
  non_free_product_prices = @available_product_prices.reject { |billing_product_price| billing_product_price.unit_amount == 0 }
  json.array! non_free_product_prices do |billing_product_price|
    json.id billing_product_price.id
    json.name billing_product_price.billing_product.product_name
    json.description "<p> #{billing_product_price.limits['agents'].presence || 'Unlimited '.html_safe} Agents</p>
                        <p> #{billing_product_price.limits['history'].presence || 'Unlimited '.html_safe} Days Chat History</p>"
    json.unit_amount billing_product_price.unit_amount
    json.no_of_allowed_agents billing_product_price.limits['agents']
    json.chat_history billing_product_price.limits['history']
  end
end
