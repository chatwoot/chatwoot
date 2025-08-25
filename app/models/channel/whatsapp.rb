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
  PROVIDERS = %w[default whatsapp_cloud whapi].freeze

  validates :provider, inclusion: { in: PROVIDERS }
  validates :phone_number, presence: true, uniqueness: true
  validate :validate_provider_config

  after_create :sync_templates
  after_destroy_commit :perform_provider_cleanup
  after_update :invalidate_provider_cache, if: -> { saved_change_to_provider_config? || saved_change_to_provider? }

  def name
    'Whatsapp'
  end

  def provider_config_object
    @provider_config_object ||= Whatsapp::ProviderConfigFactory.create(self)
  end

  def provider_service
    @provider_service ||= Whatsapp::ProviderServiceFactory.create(self)
  end

  def mark_message_templates_updated
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:message_templates_last_updated, Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end

  delegate :send_message, to: :provider_service
  delegate :send_template, to: :provider_service
  delegate :sync_templates, to: :provider_service
  delegate :media_url, to: :provider_service
  delegate :api_headers, to: :provider_service

  private

  def validate_provider_config
    errors.add(:provider_config, 'Invalid Credentials') unless provider_config_object.validate_config?
  end

  def perform_provider_cleanup
    provider_config_object.cleanup_on_destroy
  end

  def invalidate_provider_cache
    @provider_config_object = nil
    @provider_service = nil
  end
end
