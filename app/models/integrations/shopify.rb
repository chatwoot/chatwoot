# == Schema Information
#
# Table name: integrations_shopify
#
#  id           :integer          not null, primary key
#  access_token :string
#  account_name :string
#  api_key      :string
#  api_secret   :string
#  redirect_url :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer
#
class Integrations::Shopify < ApplicationRecord
  include Reauthorizable

  attr_readonly :account_id
  validates :account_id, presence: true
  belongs_to :account
  
  self.table_name = "integrations_shopify"
end
  
