# CUSTOMIZAÇÃO_SYNAPSEOS
# Integração com a Hyperflow (BSP oficial da Meta no Brasil).
# Hyperflow tipicamente expõe uma API compatível com a WhatsApp Cloud API,
# mas com base_url e auth próprios. Os pontos marcados `TODO_HYPERFLOW`
# precisam ser revisados contra a documentação oficial quando as credenciais
# estiverem em mãos.
class Whatsapp::Providers::HyperflowService < Whatsapp::Providers::BaseService
  # TODO_HYPERFLOW: confirmar base_url. Muitos BSPs usam o domínio próprio
  # como proxy da Graph API da Meta. Caso seja esse o modelo, base_url
  # virá do provider_config e api_base_path retorna algo como
  # "#{base_url}/v17.0/#{phone_id}".
  DEFAULT_API_HOST = 'https://api.hyperflow.com.br'.freeze

  def send_message(phone_number, message)
    @message = message

    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_interactive_text_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, template_info, message)
    request_body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: phone_number,
      type: 'template',
      template: template_body_parameters(template_info)
    }

    response = HTTParty.post("#{phone_id_path}/messages", headers: api_headers, body: request_body.to_json)
    process_response(response, message)
  end

  def sync_templates
    whatsapp_channel.mark_message_templates_updated
    templates = fetch_whatsapp_templates("#{business_account_path}/message_templates")
    whatsapp_channel.update(message_templates: templates, message_templates_last_updated: Time.now.utc) if templates.present?
  end

  def validate_provider_config?
    response = HTTParty.get("#{business_account_path}/message_templates", headers: api_headers)
    response.success?
  end

  def api_headers
    {
      'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}",
      'Content-Type' => 'application/json'
    }
  end

  def media_url(media_id)
    "#{api_base_path}/#{media_id}"
  end

  private

  def api_base_path
    whatsapp_channel.provider_config['api_base_url'].presence || DEFAULT_API_HOST
  end

  def phone_id_path
    "#{api_base_path}/#{whatsapp_channel.provider_config['phone_number_id']}"
  end

  def business_account_path
    "#{api_base_path}/#{whatsapp_channel.provider_config['business_account_id']}"
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: { messaging_product: 'whatsapp', to: phone_number, text: { body: message.content } }.to_json
    )
    process_response(response, message)
  end

  # TODO_HYPERFLOW: implementar envio com mídia seguindo o contrato do Hyperflow.
  def send_attachment_message(phone_number, message)
    Rails.logger.warn("[HYPERFLOW] send_attachment_message not implemented yet — message=#{message.id}")
    send_text_message(phone_number, message)
  end

  # TODO_HYPERFLOW: mapear o tipo interactive correto.
  def send_interactive_text_message(phone_number, message)
    send_text_message(phone_number, message)
  end

  def fetch_whatsapp_templates(url)
    response = HTTParty.get(url, headers: api_headers)
    return [] unless response.success?

    Array(response['data'])
  end

  def template_body_parameters(template_info)
    {
      name: template_info[:name],
      language: { code: template_info[:language] || 'pt_BR' },
      components: template_info[:components] || []
    }
  end
end
