# == Schema Information
#
# Table name: channel_email
#
#  id               :bigint           not null, primary key
#  email            :string           not null
#  forward_to_email :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :integer          not null
#
# Indexes
#
#  index_channel_email_on_email             (email) UNIQUE
#  index_channel_email_on_forward_to_email  (forward_to_email) UNIQUE
#

class Channel::Email < ApplicationRecord
  self.table_name = 'channel_email'
  EDITABLE_ATTRS = [:email].freeze

  validates :account_id, presence: true
  belongs_to :account
  validates :email, uniqueness: true
  validates :forward_to_email, uniqueness: true

  has_one :inbox, as: :channel, dependent: :destroy
  before_validation :ensure_forward_to_email, on: :create

  def name
    'Email'
  end

  def has_24_hour_messaging_window?
    false
  end

  private

  def ensure_forward_to_email
    self.forward_to_email ||= "#{SecureRandom.hex}@#{account.inbound_email_domain}"
  end
end
