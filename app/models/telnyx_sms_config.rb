# == Schema Information
#
# Table name: telnyx_sms_configs
#
#  id                    :bigint           not null, primary key
#  api_key               :string           not null
#  messaging_profile_id  :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  channel_telnyx_sms_id :bigint           not null
#
# Indexes
#
#  index_telnyx_sms_configs_on_channel_telnyx_sms_id  (channel_telnyx_sms_id) UNIQUE
#
class TelnyxSmsConfig < ApplicationRecord
  belongs_to :channel_telnyx_sms, class_name: 'Channel::TelnyxSms'

  encrypts :api_key if Chatwoot.encryption_configured?

  validates :api_key, :messaging_profile_id, presence: true
end
