class Whatsapp::JusmonitoriaAlertTemplateMetaClient
  WHATSAPP_API_VERSION = 'v22.0'.freeze

  def initialize(channel)
    @channel = channel
  end

  def fetch_template_details(name:, language:, fields:)
    response = HTTParty.get(
      "#{business_account_path}/message_templates?name=#{name}&fields=#{fields}",
      headers: api_headers
    )
    return { success: false, error: response.body } unless response.success?

    template = Array(response['data']).find do |item|
      item['name'] == name && item['language'].to_s.casecmp(language).zero?
    end
    { success: true, template: template }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def delete_template(name:)
    response = HTTParty.delete(
      "#{business_account_path}/message_templates?name=#{name}",
      headers: api_headers
    )
    return { success: true } if response.success?

    { success: false, error: response.body.presence || 'Falha ao apagar template rejeitado' }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  private

  def business_account_path
    "#{api_base_path}/#{WHATSAPP_API_VERSION}/#{@channel.provider_config['business_account_id']}"
  end

  def api_headers
    {
      'Authorization' => "Bearer #{@channel.provider_config['api_key']}",
      'Content-Type' => 'application/json'
    }
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end
end
