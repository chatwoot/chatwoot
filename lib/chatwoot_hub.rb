class ChatwootHub
  BASE_URL = 'https://hub.chatwoot.com'.freeze

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
end
