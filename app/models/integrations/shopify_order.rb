# == Schema Information
#
# Table name: integrations_shopify_order
#
#  id                  :integer          not null, primary key
#  cancelled_at        :string
#  closed_at           :string
#  currency            :string
#  current_total_price :string
#  order_created_at    :string
#  order_number        :string
#  order_status_url    :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :integer
#  customer_id         :integer
#  order_id            :string
#
class Integrations::ShopifyOrder < ApplicationRecord
    include Reauthorizable

    attr_readonly :account_id
    validates :account_id, presence: true
    has_one :shopify_customer, foreign_key: 'customer_id'
    has_many :shopify_order_item

    self.table_name = "integrations_shopify_order"
end