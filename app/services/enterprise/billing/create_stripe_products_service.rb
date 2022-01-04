class Enterprise::Billing::CreateStripeProductsService
  PRODUCTS = [
    { 
      name: 'Hacker',
      prices: [{unit_amount: 0, currency: 'usd',  recurring: {interval: 'month', usage_type: 'licensed' }, billing_scheme: 'per_unit'}]
    },
    { 
      name: 'Startup',
      prices: [{unit_amount: 1900, currency: 'usd', recurring: {interval: 'month', usage_type: 'licensed' }, billing_scheme: 'per_unit'}]
    },
    { 
      name: 'Business',
       prices: [{unit_amount: 3900, currency: 'usd', recurring: {interval: 'month', usage_type: 'licensed' }, billing_scheme: 'per_unit'}]
    }
  ]

  def self.perform
    PRODUCTS.each do |product|
      stripe_product = Stripe::Product.create(name: product[:name])
      product[:prices].each do |price|
        stripe_price = Stripe::Price.create(**price.merge(product: stripe_product.id))
      end
    end  
  end
end
