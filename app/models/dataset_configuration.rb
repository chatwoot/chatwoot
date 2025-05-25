# frozen_string_literal: true

class DatasetConfiguration < ApplicationRecord
  belongs_to :account
  has_many :inbox_dataset_mappings, dependent: :destroy
  has_many :inboxes, through: :inbox_dataset_mappings
  has_many :facebook_ads_trackings, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :platform, presence: true, inclusion: { in: %w[facebook instagram meta] }
  validates :pixel_id, presence: true
  validates :access_token, presence: true
  validates :default_event_name, presence: true
  validates :default_currency, presence: true

  scope :enabled, -> { where(enabled: true) }
  scope :for_platform, ->(platform) { where(platform: platform) }

  # Platform constants
  PLATFORMS = {
    facebook: 'facebook',
    instagram: 'instagram',
    meta: 'meta' # For shared Facebook/Instagram pixels
  }.freeze

  def facebook?
    platform == PLATFORMS[:facebook]
  end

  def instagram?
    platform == PLATFORMS[:instagram]
  end

  def meta?
    platform == PLATFORMS[:meta]
  end

  def supports_channel?(channel)
    case platform
    when PLATFORMS[:facebook]
      channel.is_a?(Channel::FacebookPage)
    when PLATFORMS[:instagram]
      channel.is_a?(Channel::FacebookPage) && channel.instagram_id.present?
    when PLATFORMS[:meta]
      channel.is_a?(Channel::FacebookPage)
    else
      false
    end
  end

  def conversion_event_data(tracking, override_config = {})
    config = base_config.merge(override_config)

    {
      event_name: config['event_name'] || default_event_name,
      event_time: tracking.created_at.to_i,
      action_source: action_source_for_platform,
      user_data: user_data_for_tracking(tracking),
      custom_data: custom_data_for_tracking(tracking, config),
      event_source_url: event_source_url_for_tracking(tracking),
      opt_out: false
    }.compact
  end

  def test_connection
    Facebook::TestDatasetConnectionService.new(dataset_configuration: self).test
  end

  def summary_data
    {
      id: id,
      name: name,
      platform: platform,
      pixel_id: pixel_id,
      enabled: enabled,
      default_event_name: default_event_name,
      default_event_value: default_event_value,
      default_currency: default_currency,
      inboxes_count: inboxes.count,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def detailed_data
    summary_data.merge(
      description: description,
      auto_send_conversions: auto_send_conversions,
      test_event_code: test_event_code,
      additional_config: additional_config,
      mapped_inboxes: inboxes.map do |inbox|
        {
          id: inbox.id,
          name: inbox.name,
          channel_type: inbox.channel.class.name
        }
      end
    )
  end

  private

  def base_config
    {
      'event_name' => default_event_name,
      'event_value' => default_event_value,
      'currency' => default_currency
    }.merge(additional_config || {})
  end

  def action_source_for_platform
    case platform
    when PLATFORMS[:instagram]
      'chat' # Instagram messages
    else
      'chat' # Facebook messages
    end
  end

  def user_data_for_tracking(tracking)
    {
      external_id: tracking.contact.id.to_s,
      client_ip_address: nil,
      client_user_agent: nil,
      fb_login_id: tracking.contact.get_source_id(tracking.inbox.id)
    }.compact
  end

  def custom_data_for_tracking(tracking, config)
    {
      content_name: tracking.ad_title,
      content_category: platform_content_category,
      value: config['event_value'] || default_event_value || 0,
      currency: config['currency'] || default_currency,
      content_ids: [tracking.ad_id].compact,
      contents: [
        {
          id: tracking.ad_id,
          quantity: 1,
          item_price: config['event_value'] || default_event_value || 0
        }
      ].compact
    }.compact
  end

  def platform_content_category
    case platform
    when PLATFORMS[:instagram]
      'instagram_messaging'
    when PLATFORMS[:facebook]
      'facebook_messaging'
    else
      'messaging'
    end
  end

  def event_source_url_for_tracking(tracking)
    case platform
    when PLATFORMS[:instagram]
      "https://www.instagram.com/#{tracking.inbox.channel.instagram_id}/"
    else
      "https://m.me/#{tracking.inbox.channel.page_id}?ref=#{tracking.ref_parameter}"
    end
  end
end
