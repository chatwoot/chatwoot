# frozen_string_literal: true

class InboxDatasetMapping < ApplicationRecord
  belongs_to :inbox
  belongs_to :dataset_configuration

  validates :inbox_id, uniqueness: { scope: :dataset_configuration_id }

  scope :enabled, -> { where(enabled: true) }

  def effective_config
    base_config = dataset_configuration.additional_config || {}
    override_config = self.override_config || {}
    base_config.merge(override_config)
  end

  def can_send_conversions?
    enabled? &&
    dataset_configuration.enabled? &&
    dataset_configuration.supports_channel?(inbox.channel)
  end

  def event_name
    override_config&.dig('event_name') || dataset_configuration.default_event_name
  end

  def event_value
    override_config&.dig('event_value') || dataset_configuration.default_event_value
  end

  def currency
    override_config&.dig('currency') || dataset_configuration.default_currency
  end

  def summary_data
    {
      id: id,
      inbox_id: inbox_id,
      dataset_configuration_id: dataset_configuration_id,
      enabled: enabled,
      dataset_name: dataset_configuration.name,
      dataset_platform: dataset_configuration.platform,
      dataset_pixel_id: dataset_configuration.pixel_id,
      effective_event_name: event_name,
      effective_event_value: event_value,
      effective_currency: currency,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def detailed_data
    summary_data.merge(
      override_config: override_config,
      dataset_configuration: dataset_configuration.summary_data,
      inbox: {
        id: inbox.id,
        name: inbox.name,
        channel_type: inbox.channel.class.name
      }
    )
  end
end
