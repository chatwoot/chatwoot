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

  # Set on create: the number is what the carrier routes to this inbox, so an
  # in-place edit would drift from the telco side. Renaming happens on the
  # inbox; a new number means a new inbox.
  EDITABLE_ATTRS = [:phone_number, :pathors_phone_number_id].freeze

  attr_readonly :phone_number

  # Which entry in the Pathors phone-number registry this inbox holds. Blank on
  # inboxes created before numbers were bound, which is why the unbind below is
  # conditional rather than assumed.
  store_accessor :additional_attributes, :pathors_phone_number_id

  validates :phone_number, presence: true, uniqueness: { scope: :account_id },
                           format: { with: /\+[1-9]\d{1,14}\z/ }

  after_destroy_commit :release_pathors_phone_number

  def name
    'Voice'
  end

  private

  def release_pathors_phone_number
    return if pathors_phone_number_id.blank?

    Pathors::PhoneNumbersService.new(account: account).unbind(phone_number_id: pathors_phone_number_id)
  end
end
