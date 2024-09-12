require 'administrate/field/base'

class CustomAttributeField < Administrate::Field::Base
  def to_s
    if data.present?
      data.to_json
    else
      { plan_name: nil, stripe_price_id: nil, stripe_product_id: nil, stripe_customer_id: nil,
        subscription_status: nil, subscription_ends_on: nil, stripe_subscription_id: nil }.to_json
    end
  end
end
