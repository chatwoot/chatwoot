class ConversationMonitors::Configuration
  MODEL = 'jev-1.13.0'.freeze
  THRESHOLD = 0.6
  CONTEXT_VERSION = 1
  MAX_MONITORS = 20
  MAX_CONTEXT_BYTES = 28_000
  MAX_CUSTOMER_CONTEXT_BYTES = 4_000
  LIVE_MESSAGE_LIMIT = 5
  MAX_REQUEST_BYTES = 60_000

  def self.configured?
    ENV['TYPESAFE_API_KEY'].present?
  end

  def self.model
    ENV.fetch('TYPESAFE_MODEL', MODEL)
  end

  def self.max_monitors
    Integer(ENV.fetch('CONVERSATION_MONITORS_LIMIT', MAX_MONITORS))
  end

  def self.attribute_keys
    ENV.fetch('CONVERSATION_MONITORS_ATTRIBUTES', '').split(',').map(&:strip).reject(&:blank?)
  end
end
