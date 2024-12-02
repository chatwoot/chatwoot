# == Schema Information
#
# Table name: orders
#
#  id                   :bigint           not null, primary key
#  cart_hash            :string
#  cart_tax             :string
#  created_via          :string
#  currency             :string
#  customer_ip_address  :string
#  customer_note        :string
#  customer_user_agent  :string
#  date_completed       :datetime
#  date_completed_gmt   :datetime
#  date_created         :datetime
#  date_created_gmt     :datetime
#  date_modified        :datetime
#  date_modified_gmt    :datetime
#  date_paid            :datetime
#  date_paid_gmt        :datetime
#  discount_coupon      :string
#  discount_tax         :string
#  discount_total       :string
#  order_key            :string
#  order_number         :string
#  payment_method       :string
#  payment_method_title :string
#  payment_status       :string
#  platform             :string
#  prices_include_tax   :boolean          default(FALSE), not null
#  set_paid             :boolean          default(FALSE), not null
#  shipping_tax         :string
#  shipping_total       :string
#  status               :string
#  total                :string
#  total_tax            :string
#  tracking_code        :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :integer
#  contact_id           :integer
#  transaction_id       :string
#
class Order < ApplicationRecord
  belongs_to :contact
  belongs_to :account

  has_many :order_items, dependent: :destroy_async
  validates :order_number, presence: true
end
