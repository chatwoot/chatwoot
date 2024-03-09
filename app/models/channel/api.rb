# == Schema Information
#
# Table name: channel_api
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  hmac_mandatory        :boolean          default(FALSE)
#  hmac_token            :string
#  identifier            :string
#  webhook_url           :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#
# Indexes
#
#  index_channel_api_on_hmac_token  (hmac_token) UNIQUE
#  index_channel_api_on_identifier  (identifier) UNIQUE
#

class Channel::Api < ApplicationRecord
  include Channelable

  self.table_name = 'channel_api'
  EDITABLE_ATTRS = [:webhook_url, :account_id, :hmac_mandatory, { additional_attributes: {} }].freeze

  has_secure_token :identifier
  has_secure_token :hmac_token
  validate :ensure_valid_agent_reply_time_window
  validates :webhook_url, length: { maximum: Limits::URL_LENGTH_LIMIT }

  def name
    'API'
  end

  def api_base_path
    "#{ENV.fetch('FRONTEND_URL', nil)}/api/v1"
  end

  def messaging_window_enabled?
    additional_attributes.present? && additional_attributes['agent_reply_time_window'].present?
  end

  def send_message(inbox_id, contact_id, message)
    access_token = AccessToken.find_by(:owner_id => account_id)
    conversation = get_or_create_conversation(inbox_id, contact_id)
    send_text_message(conversation.id, message, access_token.token)
  end

  private

  def send_text_message(conversation_id, message, access_token)
    body = message_body(message)
    response = HTTParty.post(
      "#{api_base_path}/accounts/#{account_id}/conversations/#{conversation_id}/messages",
      headers: {
        'Content-Type' => 'application/json',
        'api_access_token' => access_token
      },
      body: body.to_json
    )

    response.success? ? response.parsed_response['id'] : nil
  end

  def message_body(message_content)
    {
      'content' => message_content,
      'message_type' => 'outgoing',
      'private' => false
    }
  end

  def get_or_create_conversation(inbox_id, contact_id)
    Conversation.find_by(
      contact_id: contact_id,
      inbox_id: inbox_id,
      status: [0, 2]
    ) || Conversation.new(
      contact_id: contact_id,
      inbox_id: inbox_id,
      account_id: account_id,
      status: 2,
    ) # TODO: fix create conversation
  end

  def ensure_valid_agent_reply_time_window
    return if additional_attributes['agent_reply_time_window'].blank?
    return if additional_attributes['agent_reply_time_window'].to_i.positive?

    errors.add(:agent_reply_time_window, 'agent_reply_time_window must be greater than 0')
  end
end
