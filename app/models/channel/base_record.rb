class Channel::BaseRecord < ApplicationRecord
  validates :account_id, presence: true
  belongs_to :account
  has_one :inbox, as: :channel, dependent: :destroy

  def has_24_hour_messaging_window?
    false
  end
end
