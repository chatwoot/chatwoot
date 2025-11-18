# frozen_string_literal: true

require 'agents'

Rails.application.config.after_initialize do
  # Skip database operations during asset precompilation, rake tasks, and migrations
  next if Rails.env.precompiling? || defined?(Rails::Console) ||
          ARGV.include?('db:migrate') || ARGV.include?('db:chatwoot_prepare') ||
          ARGV.include?('assets:precompile') || ENV['SKIP_DB_OPERATIONS']
  
  api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  model = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || OpenAiConstants::DEFAULT_MODEL
  api_endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value || OpenAiConstants::DEFAULT_ENDPOINT

  if api_key.present?
    Agents.configure do |config|
      config.openai_api_key = api_key
      if api_endpoint.present?
        api_base = "#{api_endpoint.chomp('/')}/v1"
        config.openai_api_base = api_base
      end
      config.default_model = model
      config.debug = false
    end
  end
rescue StandardError => e
  Rails.logger.error "Failed to configure AI Agents SDK: #{e.message}"
end
