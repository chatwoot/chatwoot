class Whatsapp::TemplateSyncService
  WHATSAPP_API_VERSION = 'v14.0'.freeze

  def initialize(inbox:)
    @inbox = inbox
    @account = inbox.account
    @whatsapp_channel = inbox.channel
  end

  def perform
    templates_data = fetch_all_templates
    upsert_templates(templates_data)
    { success: true, synced_count: templates_data.size }
  rescue StandardError => e
    Rails.logger.error "WhatsApp template sync failed for inbox #{@inbox.id}: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def fetch_all_templates
    url = "#{business_account_path}/message_templates?access_token=#{@whatsapp_channel.provider_config['api_key']}"
    fetch_paginated(url)
  end

  def fetch_paginated(url, collected = [])
    response = HTTParty.get(url)
    return collected unless response.success?

    data = response['data'] || []
    collected.concat(data)

    next_url = response.dig('paging', 'next')
    return collected if next_url.blank?

    fetch_paginated(next_url, collected)
  end

  def upsert_templates(templates_data)
    existing = load_existing_templates
    synced_keys = Set.new

    templates_data.each do |template_data|
      key = [template_data['name'], template_data['language']]
      synced_keys.add(key)
      upsert_single_template(existing[key], template_data)
    end

    disable_stale_templates(existing, synced_keys)
  end

  def load_existing_templates
    @account.message_templates
            .where(inbox_id: @inbox.id, channel_type: 'Channel::Whatsapp')
            .index_by { |t| [t.name, t.language] }
  end

  def upsert_single_template(record, template_data)
    attrs = build_template_attrs(template_data)

    if record
      record.update!(attrs)
    else
      @account.message_templates.create!(attrs.merge(inbox_id: @inbox.id))
    end
  end

  def build_template_attrs(template_data)
    {
      name: template_data['name'],
      language: template_data['language'],
      category: map_category(template_data['category']),
      status: map_status(template_data['status']),
      content: { 'components' => template_data['components'] || [] },
      platform_template_id: template_data['id'],
      channel_type: 'Channel::Whatsapp',
      last_synced_at: Time.current
    }
  end

  def disable_stale_templates(existing, synced_keys)
    existing.except(*synced_keys).each_value { |record| record.update!(status: :disabled) }
  end

  CATEGORY_MAP = { 'marketing' => :marketing, 'utility' => :utility, 'authentication' => :authentication }.freeze
  STATUS_MAP = { 'approved' => :approved, 'pending' => :pending, 'rejected' => :rejected, 'paused' => :paused, 'disabled' => :disabled }.freeze

  def map_category(category_str)
    CATEGORY_MAP.fetch(category_str.to_s.downcase, :utility)
  end

  def map_status(status_str)
    STATUS_MAP.fetch(status_str.to_s.downcase, :pending)
  end

  def business_account_path
    "#{api_base_path}/#{WHATSAPP_API_VERSION}/#{@whatsapp_channel.provider_config['business_account_id']}"
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end
end
