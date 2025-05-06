# == Schema Information
#
# Table name: shopee_vouchers
#
#  id         :bigint           not null, primary key
#  code       :string           not null
#  end_time   :datetime
#  meta       :jsonb
#  name       :string           not null
#  start_time :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  shop_id    :bigint           not null
#  voucher_id :bigint           not null
#
# Indexes
#
#  index_shopee_vouchers_on_code        (code) UNIQUE
#  index_shopee_vouchers_on_shop_id     (shop_id)
#  index_shopee_vouchers_on_voucher_id  (voucher_id) UNIQUE
#
class Shopee::Voucher < ApplicationRecord
  scope :sendable, -> { where(end_time: Time.current..).order(:end_time) }

  validates :shop_id, presence: true
  validates :voucher_id, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
