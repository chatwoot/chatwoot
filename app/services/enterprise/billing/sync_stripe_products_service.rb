class Enterprise::Billing::SyncStripeProductsService
  def self.perform
    # Fetch all of our active products from Stripe
    Stripe::Product.list['data'].each do |product|
      next unless product&.metadata&.[]('product') == 'OneHash_Chat'

      if product['active']
        billing_product = Enterprise::BillingProduct.find_or_create_by(product_stripe_id: product['id'])
        billing_product.update({
                                 product_name: product['name'],
                                 product_description: product['description'],
                                 active: product['active']
                               })
      else
        billing_product = Enterprise::BillingProduct.find_by(product_stripe_id: product['id'])
        next if billing_product.blank?

        billing_product.update({
                                 product_name: product['name'],
                                 product_description: product['description'],
                                 active: product['active']
                               })
        billing_product.billing_product_prices.update_all(active: false)
      end
    end

    # Fetch all of our active prices from Stripe
    Stripe::Plan.list['data'].each do |plan|
      billing_product = Enterprise::BillingProduct.find_by(product_stripe_id: plan['product'])

      next if billing_product.blank?

      billing_product_price = billing_product.billing_product_prices.find_or_create_by(price_stripe_id: plan['id'])
      billing_product_price.update({
                                     stripe_nickname: plan['nickname'],
                                     unit_amount: plan['amount_decimal'],
                                     active: plan['active']
                                   })
    end
  end
end
