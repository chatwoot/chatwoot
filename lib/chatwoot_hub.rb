class ChatwootHub
  BASE_URL = ENV['CHATWOOT_HUB_URL'] || 'https://hub.chatwoot.com'

  def self.instance_config
    {
      installationVersion: Chatwoot.config[:version],
      installationHost: URI.parse(ENV.fetch('FRONTEND_URL', '')).host
    }
  end

  def self.latest_version
    begin
      response = RestClient.get(BASE_URL, { params: instance_config })
      version = JSON.parse(response)['version']
    rescue *ExceptionList::REST_CLIENT_EXCEPTIONS, *ExceptionList::URI_EXCEPTIONS => e
      Rails.logger.info "Exception: #{e.message}"
    rescue StandardError => e
      Raven.capture_exception(e)
    end
    version
  end

  def self.register_instance(info)
    RestClient.post("#{BASE_URL}/register_instance", info.merge(instance_config).to_json, { content_type: :json, accept: :json })
  rescue *ExceptionList::REST_CLIENT_EXCEPTIONS, *ExceptionList::URI_EXCEPTIONS => e
    Rails.logger.info "Exception: #{e.message}"
  rescue StandardError => e
    Raven.capture_exception(e)
  end
end
