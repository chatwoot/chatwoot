# Vapi settings from Super Admin → Captain. Captain answers calls only when all of them are set.
module Voice::Captain::VapiConfig
  API_KEY = 'CAPTAIN_VAPI_API_KEY'.freeze
  PHONE_NUMBER_ID = 'CAPTAIN_VAPI_PHONE_NUMBER_ID'.freeze
  WEBHOOK_SECRET = 'CAPTAIN_VAPI_WEBHOOK_SECRET'.freeze
  NAMES = [API_KEY, PHONE_NUMBER_ID, WEBHOOK_SECRET].freeze

  def self.configured?
    NAMES.all? { |name| value(name).present? }
  end

  def self.api_key
    value(API_KEY)
  end

  def self.phone_number_id
    value(PHONE_NUMBER_ID)
  end

  def self.webhook_secret
    value(WEBHOOK_SECRET)
  end

  def self.value(name)
    InstallationConfig.find_by(name: name)&.value
  end
end
