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

  # Guarda contra template não-sincronizado: o TemplateProcessorService procura
  # o template em channel.message_templates (snapshot local) e, quando não
  # acha, devolve `parameters` NIL — o envio sai sem components e a Meta
  # rejeita com o genérico "(#132000) Number of parameters does not match".
  # Incidente 2026-08-07: template novo aprovado na WABA mas ainda ausente do
  # snapshot ⇒ disparo queimado com erro que não aponta pra causa. Aqui a
  # falha vira explícita ANTES de gastar a chamada na Meta.
  def send_template(phone_number, template_info, message)
    if template_info[:parameters].blank? && template_expects_parameters?(template_info[:name])
      message&.update!(
        status: :failed,
        external_error: "Template '#{template_info[:name]}' não está sincronizado/aprovado neste inbox " \
                        '— rode sync_templates antes de enviar.'
      )
      return nil
    end

    super
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

  # O template declara placeholders ({{1}}…) no corpo? Se o snapshot local não
  # tem o template, tratamos como "espera parâmetros" — é o caso perigoso
  # (enviar sem components) e o operador precisa saber que falta sincronizar.
  def template_expects_parameters?(name)
    template = whatsapp_channel.message_templates&.find { |t| t['name'] == name }
    return true if template.blank?

    body = template['components']&.find { |c| c['type'].to_s.casecmp('body').zero? }
    body.present? && body['text'].to_s.include?('{{')
  end

  # A 360dialog devolve erros em DOIS shapes: passthrough da Meta
  # ({"error"=>{"message"=>...}}) e erros próprios do gateway com `error`
  # STRING ({"error"=>"This number is blocked due to lack of payment..."}).
  # O error_message herdado faz dig('error','message') e explode com TypeError
  # no shape string — o handle_error crasha ANTES de marcar a mensagem como
  # failed: fila de SendReplyJob morre em retry e o erro real fica invisível
  # (incidente 2026-08-07: bloqueio de pagamento silencioso por 40min).
  def error_message(response)
    error = response.parsed_response.is_a?(Hash) ? response.parsed_response['error'] : nil
    return error if error.is_a?(String)

    error&.dig('message')
  end

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
