# == Schema Information
#
# Table name: orders
#
#  id                 :bigint           not null, primary key
#  billing_address    :jsonb
#  cancel_reason      :string
#  cancelled_at       :datetime
#  currency           :string
#  financial_status   :string
#  fulfillment_status :string
#  line_items         :jsonb            not null
#  name               :string
#  note               :text
#  order_status_url   :string
#  refunds            :jsonb            not null
#  shipping_address   :jsonb
#  shipping_lines     :jsonb            not null
#  subtotal_price     :decimal(15, 2)
#  tags               :string
#  total_price        :decimal(15, 2)
#  total_tax          :decimal(15, 2)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint
#  customer_id        :integer
#
# Indexes
#
#  index_orders_on_account_id   (account_id)
#  index_orders_on_created_at   (created_at)
#  index_orders_on_customer_id  (customer_id)
#  index_orders_on_name         (name)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Order < ApplicationRecord
  belongs_to :account, optional: true
end
