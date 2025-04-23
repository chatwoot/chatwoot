# == Schema Information
#
# Table name: shopee_orders
#
#  id                     :bigint           not null, primary key
#  actual_shipping_fee    :integer
#  booking_sn             :string
#  buyer_cancel_reason    :string
#  cancel_by              :string
#  cancel_reason          :string
#  cod                    :boolean
#  create_time            :datetime
#  days_to_ship           :integer
#  estimated_shipping_fee :integer
#  message_to_seller      :string
#  note                   :string
#  number                 :string
#  pay_time               :datetime
#  payment_method         :string
#  pickup_done_time       :datetime
#  recipient_address      :text
#  shipping_carrier       :string
#  status                 :string
#  total_amount           :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class Shopee::Order < ApplicationRecord
  has_many :order_items, class_name: 'Shopee::OrderItem'
end
