# == Schema Information
#
# Table name: channel_api
#
#  id          :bigint           not null, primary key
#  webhook_url :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer          not null
#

class Channel::Api < ApplicationRecord
  self.table_name = 'channel_api'

  validates :account_id, presence: true
  belongs_to :account

  has_one :inbox, as: :channel, dependent: :destroy

  def has_24_hour_messaging_window?
    false
  end
end
