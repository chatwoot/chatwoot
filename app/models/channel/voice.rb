# == Schema Information
#
# Table name: channel_voice
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  phone_number          :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#
# Indexes
#
#  index_channel_voice_on_account_id_and_phone_number  (account_id,phone_number) UNIQUE
#

class Channel::Voice < ApplicationRecord
  include Channelable

  self.table_name = 'channel_voice'

  # Permitted on create only: the number is what the carrier routes to this inbox,
  # so an in-place edit would drift from the telco side. Renaming happens on the
  # inbox; a new number means a new inbox.
  EDITABLE_ATTRS = [:phone_number].freeze

  attr_readonly :phone_number

  validates :phone_number, presence: true, uniqueness: { scope: :account_id },
                           format: { with: /\+[1-9]\d{1,14}\z/ }

  def name
    'Voice'
  end
end
