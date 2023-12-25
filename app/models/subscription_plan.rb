# == Schema Information
#
# Table name: subscription_plans
#
#  id                :bigint           not null, primary key
#  plan_name         :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  stripe_price_id   :string
#  stripe_product_id :string
#
class SubscriptionPlan < ApplicationRecord
end
