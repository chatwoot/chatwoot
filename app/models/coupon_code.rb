# == Schema Information
#
# Table name: coupon_codes
#
#  id           :bigint           not null, primary key
#  account_name :string
#  code         :string
#  expiry_date  :datetime
#  partner      :string
#  redeemed_at  :datetime
#  status       :string           default("new")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer
#
class CouponCode < ApplicationRecord
  belongs_to :account, optional: true
  validates :code, uniqueness: true
end
