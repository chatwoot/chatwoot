# == Schema Information
#
# Table name: channel_whatsapp
#
#  id                             :bigint           not null, primary key
#  message_templates              :jsonb
#  message_templates_last_updated :datetime
#  phone_number                   :string           not null
#  provider                       :string           default("default")
#  provider_config                :jsonb
#  provider_connection            :jsonb
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  account_id                     :integer          not null
#
# Indexes
#
#  index_channel_whatsapp_on_phone_number  (phone_number) UNIQUE
#

class Channel::Whatsapp < ApplicationRecord
  include Channelable
  include Reauthorizable

  self.table_name = 'channel_whatsapp'
  EDITABLE_ATTRS = [:phone_number, :provider, { provider_config: {} }].freeze

  # default at the moment is 360dialog lets change later.
  PROVIDERS = %w[default whatsapp_cloud baileys].freeze
  before_validation :ensure_webhook_verify_token

  validates :provider, inclusion: { in: PROVIDERS }
  validates :phone_number, presence: true, uniqueness: true
  validate :validate_provider_config

  has_one :inbox, as: :channel, dependent: :destroy

  after_create :sync_templates

  before_destroy :disconnect_channel_provider, if: -> { provider == 'baileys' }

  def name
    'Whatsapp'
  end

  def provider_service
    case provider
    when 'whatsapp_cloud'
      Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: self)
    when 'baileys'
      Whatsapp::Providers::WhatsappBaileysService.new(whatsapp_channel: self)
    else
      Whatsapp::Providers::Whatsapp360DialogService.new(whatsapp_channel: self)
    end
  end

  def use_internal_host?
    provider == 'baileys' && ENV.fetch('BAILEYS_PROVIDER_USE_INTERNAL_HOST_URL', false)
  end

  def mark_message_templates_updated
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:message_templates_last_updated, Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def update_provider_connection!(provider_connection)
    assign_attributes(provider_connection: provider_connection)
    # NOTE: Skip `validate_provider_config?` check
    save!(validate: false)
  end

  def provider_connection_data
    data = { connection: provider_connection['connection'] }
    if Current.account_user&.administrator?
      data[:qr_data_url] = provider_connection['qr_data_url']
      data[:error] = provider_connection['error']
    end
    data
  end

  def toggle_typing_status(typing_status, conversation:)
    return unless provider_service.respond_to?(:toggle_typing_status)

    provider_service.toggle_typing_status(conversation.contact.phone_number, typing_status)
  end

  def update_presence(status)
    return unless provider_service.respond_to?(:update_presence)

    provider_service.update_presence(status)
  end

  def read_messages(messages, conversation:)
    return unless provider_service.respond_to?(:read_messages)

    provider_service.read_messages(conversation.contact.phone_number, messages)
  end

  def unread_conversation(conversation)
    return unless provider_service.respond_to?(:unread_message)

    # NOTE: For the Baileys provider, the last message is required even if it is an outgoing message.
    last_message = conversation.messages.last
    provider_service.unread_message(conversation.contact.phone_number, last_message) if last_message
  end

  delegate :setup_channel_provider, to: :provider_service
  delegate :disconnect_channel_provider, to: :provider_service
  delegate :send_message, to: :provider_service
  delegate :send_template, to: :provider_service
  delegate :sync_templates, to: :provider_service
  delegate :media_url, to: :provider_service
  delegate :api_headers, to: :provider_service

  private

  def ensure_webhook_verify_token
    provider_config['webhook_verify_token'] ||= SecureRandom.hex(16) if provider.in?(%w[whatsapp_cloud baileys])
  end

  def validate_provider_config
    errors.add(:provider_config, 'Invalid Credentials') unless provider_service.validate_provider_config?
  end
end
