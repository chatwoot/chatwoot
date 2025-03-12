# == Schema Information
#
# Table name: pricing_plans
#
#  id                :bigint           not null, primary key
#  ai_responses      :integer
#  dedicated_support :boolean          default(FALSE)
#  description       :text
#  human_agents      :integer
#  max_active_users  :integer
#  name              :string
#  openapi_access    :boolean          default(FALSE)
#  price             :integer
#  tag               :string           default("regular")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class PricingPlan < ApplicationRecord
    validates :name, :price, :description, presence: true
  end
  
