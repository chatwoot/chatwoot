class Whatsapp::Providers::Whatsapp360DialogCloudService < Whatsapp::Providers::Whatsapp360DialogService
  WEBHOOK_AUTH_HEADER = 'X-Chatwoot-360dialog-Webhook-Token'.freeze

  def sync_templates
    whatsapp_channel.mark_message_templates_updated
    response = HTTParty.get("#{api_base_path}/v1/configs/templates", headers: api_headers)
    return unless response.success?

    templates = response['waba_templates']
    whatsapp_channel.account.update_cache_key('inbox') if templates != whatsapp_channel.message_templates
    # rubocop:disable Rails/SkipsModelValidations
    whatsapp_channel.update_columns(message_templates: templates, message_templates_last_updated: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def validate_provider_config?
    webhook_secret = ENV.fetch('D360_WEBHOOK_SECRET')
    raise ArgumentError, 'D360_WEBHOOK_SECRET must be configured' if webhook_secret.blank?

    response = HTTParty.post(
      "#{api_base_path}/v1/configs/webhook",
      headers: api_headers,
      body: {
        url: "#{webhook_url_prefix}/#{whatsapp_channel.phone_number}",
        headers: { WEBHOOK_AUTH_HEADER => webhook_secret }
      }.to_json
    )
    response.success?
  end

  def media_url(media_id)
    "#{api_base_path}/#{media_id}"
  end

  private

  def api_base_path
    ENV.fetch('360DIALOG_CLOUD_BASE_URL', 'https://waba-v2.360dialog.io')
  end

  def webhook_url_prefix
    ENV.fetch('360DIALOG_CLOUD_WEBHOOK_URL') { "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/whatsapp" }
  end

  def message_request_metadata
    { messaging_product: 'whatsapp', recipient_type: 'individual' }
  end

  def template_body_parameters(template_info)
    super.except(:namespace)
  end

  def error_message(response)
    response.parsed_response.dig('error', 'message')
  end
end
