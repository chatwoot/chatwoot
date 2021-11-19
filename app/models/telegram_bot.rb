# == Schema Information
#
# Table name: telegram_bots
#
#  id         :integer          not null, primary key
#  auth_key   :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer
#

class TelegramBot < ApplicationRecord
  belongs_to :account
  has_one :inbox, as: :channel, dependent: :destroy_async
  validates_uniqueness_of :auth_key, scope: :account_id
end
