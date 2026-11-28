class Integrations::Dialogflow::Configuration
  ENDPOINTS = {
    'global' => 'dialogflow.googleapis.com',
    'asia-northeast1' => 'asia-northeast1-dialogflow.googleapis.com',
    'australia-southeast1' => 'australia-southeast1-dialogflow.googleapis.com',
    'europe-west1' => 'europe-west1-dialogflow.googleapis.com',
    'europe-west2' => 'europe-west2-dialogflow.googleapis.com'
  }.freeze
  attr_reader :region, :client_credentials

  def initialize(settings)
    settings = {} unless settings.is_a?(Hash)
    @client_credentials = Integrations::GoogleServiceAccountCredentials.for_client(settings['credentials'])
    @region = settings['region'].to_s.strip.presence || 'global'
  end

  def valid_credentials?
    client_credentials.present?
  end

  def valid_region?
    ENDPOINTS.key?(region)
  end

  def endpoint
    ENDPOINTS.fetch(region)
  end
end
