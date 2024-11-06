# == Schema Information
#
# Table name: channel_evolution
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  hmac_mandatory        :boolean          default(FALSE)
#  hmac_token            :string
#  identifier            :string
#  qr_code               :string
#  webhook_url           :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#  instance_id           :string
#
# Indexes
#
#  index_channel_evolution_on_hmac_token  (hmac_token) UNIQUE
#  index_channel_evolution_on_identifier  (identifier) UNIQUE
#

class Channel::Evolution < ApplicationRecord
  include Channelable

  self.table_name = 'channel_evolution'
  EDITABLE_ATTRS = [:webhook_url, :hmac_mandatory, { additional_attributes: {} }].freeze

  has_secure_token :identifier
  has_secure_token :hmac_token
  validate :ensure_valid_agent_reply_time_window
  validates :webhook_url, length: { maximum: Limits::URL_LENGTH_LIMIT }

  before_create :create_evolution_instance

  def name
    'EVOLUTION'
  end

  def messaging_window_enabled?
    additional_attributes.present? && additional_attributes['agent_reply_time_window'].present?
  end

  private

  def ensure_valid_agent_reply_time_window
    return if additional_attributes['agent_reply_time_window'].blank?
    return if additional_attributes['agent_reply_time_window'].to_i.positive?

    errors.add(:agent_reply_time_window, 'agent_reply_time_window must be greater than 0')
  end

  def create_evolution_instance
    payload = {
      instanceName: identifier,
      apiToken: hmac_token,
      integration: 'WHATSAPP-BAILEYS',
      qrcode: true,
      chatwootAccountId: account.id.to_s,
      chatwootToken: account.users.first.access_token.token,
      chatwootUrl: ENV.fetch('FRONTEND_URL', nil),
      chatwootSignMsg: true,
      chatwootReopenConversation: true,
      chatwootConversationPending: false,
      chatwootImportContacts: false,
      chatwootNameInbox: 'WhatsApp'
      # chatwootOrganization
    }
    byebug
    response = Evolution::Api.new('instance/create', payload).call
    byebug
    # Set QR CODE
    instance_id = response['instance'].fetch('instanceId', nil)
    self.instance_id = instance_id
    self.webhook_url = ENV.fetch('EVOLUTION_API_URL', nil) + "/chatwoot/webhook/#{identifier}"

    # Call instance/{instanceId}/connect
    connect_response = Evolution::Api.new("instance/connect/#{identifier}", {}, :get).call
    self.qr_code = connect_response.fetch('code', nil)
  end
end
