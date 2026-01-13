require 'ostruct'

class Integrations::Openai::GlobalProcessorService < Integrations::Openai::ProcessorService
  pattr_initialize [:account!, :event!]

  # Override to get account directly instead of through hook
  def hook
    # Return a mock hook object that only provides account access
    @hook ||= OpenStruct.new(account: account, settings: {})
  end

  # Override resolve_api_key to use global key directly
  def resolve_api_key
    global_key = GlobalConfig.get_value('OPENAI_API_KEY')

    if global_key.blank?
      Rails.logger.error("Global OpenAI API key not configured for account #{account.id}")
      raise StandardError, 'Global OpenAI API key not configured'
    end

    global_key
  end
end
