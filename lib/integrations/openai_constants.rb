# frozen_string_literal: true

module Integrations
  module OpenaiConstants
    # Legacy OpenAI integration defaults
    DEFAULT_ENDPOINT = 'https://api.openai.com'
    DEFAULT_MODEL = 'gpt-4o-mini'

    # Get the endpoint for legacy OpenAI integration
    # Priority: InstallationConfig > Default
    def self.endpoint
      InstallationConfig.find_by(name: 'LEGACY_OPENAI_ENDPOINT')&.value || DEFAULT_ENDPOINT
    end

    # Get the model for legacy OpenAI integration
    # Priority: ENV variable > InstallationConfig > Default
    def self.model
      ENV.fetch('OPENAI_GPT_MODEL', nil) ||
        InstallationConfig.find_by(name: 'LEGACY_OPENAI_MODEL')&.value ||
        DEFAULT_MODEL
    end
  end
end
