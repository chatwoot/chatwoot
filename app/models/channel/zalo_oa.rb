# == Schema Information
#
# Table name: channel_zalo_oa
#
#  id              :bigint           not null, primary key
#  oa_access_token :string           not null
#  refresh_token   :string           not null
#  expires_in      :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#  oa_id           :string           not null
#
# Indexes
#
#  index_channel_zalo_oa_on_oa_id_and_account_id  (oa_id,account_id) UNIQUE
#

class Channel::ZaloOa < ApplicationRecord
  include Channelable
  # include Reauthorizable

  self.table_name = 'channel_zalo_oa'
  EDITABLE_ATTRS = [:oa_access_token, :refresh_token, :expires_in].freeze

  validates :oa_access_token, presence: true, length: { maximum: 2048 }
  validates :refresh_token, presence: true, length: { maximum: 2048 }
  validates :expires_in, presence: true
  validates :account_id, presence: true
  validates :oa_id, presence: true
  validates :oa_id, uniqueness: { scope: :account_id }

  def name
    'Zalo'
  end
end
