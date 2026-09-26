class ConversationMonitors::Configuration
  MODEL = 'typesafe/jev-1.13'.freeze
  ENDPOINT = 'https://openrouter.ai/api'.freeze
  SYSTEM_ONE_PATH = '/v1/systemone'.freeze
  THRESHOLD = 0.6
  MAX_MONITORS = 20
  MONTHLY_CALL_LIMIT = 100_000
  MAX_CONTEXT_BYTES = 28_000
  MAX_CUSTOMER_CONTEXT_BYTES = 4_000
  LIVE_MESSAGE_LIMIT = 5
  MAX_REQUEST_BYTES = 60_000

  def self.enabled?(account)
    ChatwootApp.enterprise? && account.feature_enabled?('reports') && account.feature_enabled?('conversation_monitors')
  end

  def self.configured?
    api_key.present?
  end

  def self.api_key
    GlobalConfigService.load('CAPTAIN_OPENROUTER_API_KEY', nil)
  end

  def self.endpoint
    base_url = GlobalConfigService.load('CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', nil).presence || ENDPOINT
    "#{base_url.chomp('/')}#{SYSTEM_ONE_PATH}"
  end

  def self.model
    ENV.fetch('CONVERSATION_MONITORS_MODEL', MODEL)
  end

  def self.max_monitors
    Integer(ENV.fetch('CONVERSATION_MONITORS_LIMIT', MAX_MONITORS))
  end

  def self.attribute_keys
    ENV.fetch('CONVERSATION_MONITORS_ATTRIBUTES', '').split(',').map(&:strip).reject(&:blank?)
  end
end
