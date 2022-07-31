# == Schema Information
#
# Table name: integrations_shopify_order_item
#
#  id         :integer          not null, primary key
#  name       :string
#  price      :string
#  quantity   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  order_id   :integer
#
class Integrations::ShopifyOrderItem < ApplicationRecord
    include Reauthorizable

    attr_readonly :order_id
    validates :order_id, presence: true
    has_one :shopify_order, foreign_key: 'order_id'

    self.table_name = "integrations_shopify_order_item"
end
