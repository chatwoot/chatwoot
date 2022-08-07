# == Schema Information
#
# Table name: integrations_shopify_customer
#
#  id                   :integer          not null, primary key
#  email                :string
#  first_name           :string
#  last_name            :string
#  orders_count         :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :integer
#  contact_id           :integer
#  customer_id          :string
#  shopify_account_if   :integer
#
class Integrations::ShopifyCustomer < ApplicationRecord
    include Reauthorizable

    validates :account_id, presence: true
    belongs_to :account
    belongs_to :contact

    self.table_name = "integrations_shopify_customer"
end
