json.id @account.id
if @billing_subscription&.billing_product_price.present?
  json.plan_name @billing_subscription.billing_product_price.billing_product.product_name.capitalize
  json.platform_name @billing_subscription.partner.presence || ''
  json.plan_id @billing_subscription.billing_product_price.id
  json.allowed_no_agents @billing_subscription.billing_product_price.limits['agents'].presence || 'Unlimited '.html_safe
  json.allowed_no_inboxes @billing_subscription.billing_product_price.limits['inboxes']
  json.chat @billing_subscription.billing_product_price.limits['chat']
  json.chat_history @billing_subscription.billing_product_price.limits['history']
  json.plan_expiry_date @billing_subscription.current_period_end

end
json.available_product_prices do
  non_free_product_prices = @available_product_prices.reject do |billing_product_price|
    billing_product_price.price_stripe_id.nil? || billing_product_price.price_stripe_id.empty?
  end
  json.array! non_free_product_prices do |billing_product_price|
    json.id billing_product_price.id
    json.name billing_product_price.billing_product.product_name
    json.description "<p> #{billing_product_price.limits['agents'].presence || 'Unlimited '.html_safe} Agents</p>
                      <p> #{billing_product_price.limits['inboxes'].presence || 'Unlimited '.html_safe} Inboxes</p>
                      <p> #{billing_product_price.limits['chat'].presence || 'Unlimited '.html_safe} Chat</p>
                      <p> #{billing_product_price.limits['history'].presence || 'Unlimited '.html_safe} Days Chat History</p>"
    json.unit_amount billing_product_price.unit_amount
    json.no_of_allowed_agents billing_product_price.limits['agents']
    json.no_of_allowed_inboxes billing_product_price.limits['inboxes']
    json.chat billing_product_price.limits['chat']
    json.chat_history billing_product_price.limits['history']
  end
end
