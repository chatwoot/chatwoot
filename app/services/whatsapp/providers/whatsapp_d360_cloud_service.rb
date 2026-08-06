# CUSTOMIZAÇÃO_SYNAPSEOS: 360dialog como BSP/intermediário da Cloud API
# (waba-v2.360dialog.io). A API espelha a Meta Cloud API — payloads de envio
# idênticos e webhooks inbound no MESMO formato (entry/changes/value) — mas:
#   - auth via header D360-API-KEY (provider_config['api_key'] = key do Hub
#     360dialog, escopada por canal/número);
#   - endpoints SEM phone_number_id/waba_id no path (a key já identifica o
#     canal): POST {base}/messages, GET/POST {base}/message_templates;
#   - download de mídia: o GET /{media_id} devolve uma URL interna da Meta
#     (lookaside.fbsbx.com) que só é servida trocando o host pelo proxy da
#     360dialog (ver media_download_url).
# Docs: https://docs.360dialog.com/docs/guides/send-and-receive-messages
class Whatsapp::Providers::WhatsappD360CloudService < Whatsapp::Providers::WhatsappCloudService
  def api_headers
    { 'D360-API-KEY' => whatsapp_channel.provider_config['api_key'], 'Content-Type' => 'application/json' }
  end

  def sync_templates
    whatsapp_channel.mark_message_templates_updated
    templates = fetch_whatsapp_templates("#{api_base_path}/message_templates?limit=100")
    whatsapp_channel.update(message_templates: templates, message_templates_last_updated: Time.now.utc) if templates.present?
  end

  def fetch_whatsapp_templates(url)
    response = HTTParty.get(url, headers: api_headers)
    return [] unless response.success?

    templates = response['data'] || response['waba_templates'] || []
    next_url = next_url(response)

    return templates + fetch_whatsapp_templates(next_url) if next_url.present?

    templates
  end

  def validate_provider_config?
    response = HTTParty.get("#{api_base_path}/message_templates?limit=1", headers: api_headers)
    response.success?
  end

  def media_url(media_id)
    "#{api_base_path}/#{media_id}"
  end

  def media_download_url(url)
    uri = URI.parse(url)
    base = URI.parse(api_base_path)
    uri.scheme = base.scheme
    uri.host = base.host
    uri.port = base.port
    uri.to_s
  end

  private

  def api_base_path
    ENV.fetch('D360_CLOUD_BASE_URL', 'https://waba-v2.360dialog.io')
  end

  # waba-v2 não leva ids no path; os send_* herdados montam "#{phone_id_path}/messages".
  def phone_id_path
    api_base_path
  end

  def business_account_path
    api_base_path
  end
end
