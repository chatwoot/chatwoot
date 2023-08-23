class Enterprise::Billing::CreateStripeProductsService
  PRODUCTS = [
    {
      name: 'Starter',
      prices: [{ unit_amount: 0, currency: 'usd', recurring: { interval: 'month', usage_type: 'licensed' }, billing_scheme: 'per_unit' }]
    },
    {
      name: 'Plus',
      prices: [{ unit_amount: 27, currency: 'usd', recurring: { interval: 'month', usage_type: 'licensed' }, billing_scheme: 'per_unit' }]
    },
    {
      name: 'Pro',
      prices: [{ unit_amount: 270, currency: 'usd', recurring: { interval: 'year', usage_type: 'licensed' }, billing_scheme: 'per_unit' }]
    }
  ].freeze

  def self.perform
    PRODUCTS.each do |product|
      stripe_product = Stripe::Product.create(name: product[:name])
      product[:prices].each do |price|
        Stripe::Price.create(**price.merge(product: stripe_product.id))
      end
    end
  end
end
