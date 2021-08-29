# == Schema Information
#
# Table name: channel_line
#
#  id                  :bigint           not null, primary key
#  line_channel_secret :string           not null
#  line_channel_token  :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :integer          not null
#  line_channel_id     :string           not null
#
# Indexes
#
#  index_channel_line_on_line_channel_id  (line_channel_id) UNIQUE
#

class Channel::Line < ApplicationRecord
  self.table_name = 'channel_line'

  validates :account_id, presence: true
  belongs_to :account
  validates :line_channel_id, uniqueness: true, presence: true
  validates :line_channel_secret, presence: true
  validates :line_channel_token, presence: true

  has_one :inbox, as: :channel, dependent: :destroy

  def name
    'LINE'
  end

  def has_24_hour_messaging_window?
    false
  end
end
