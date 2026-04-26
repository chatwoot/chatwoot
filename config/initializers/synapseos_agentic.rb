# frozen_string_literal: true

require 'synapseos/agentic_client'

module Synapseos; end

module Synapseos::Agentic
  class NotConfiguredError < StandardError; end

  CONFIG_KEYS = %w[
    SYNAPSEOS_AGENTIC_URL
    SYNAPSEOS_AGENTIC_USER
    SYNAPSEOS_AGENTIC_PASSWORD
    SYNAPSEOS_AGENTIC_ENABLED
  ].freeze

  class << self
    def config
      {
        url: read('SYNAPSEOS_AGENTIC_URL'),
        user: read('SYNAPSEOS_AGENTIC_USER'),
        password: read('SYNAPSEOS_AGENTIC_PASSWORD'),
        enabled: ActiveModel::Type::Boolean.new.cast(read('SYNAPSEOS_AGENTIC_ENABLED'))
      }
    end

    def enabled?
      config[:enabled] == true
    end

    def client
      cfg = config
      unless cfg[:enabled] && cfg[:url].present? && cfg[:user].present? && cfg[:password].present?
        raise NotConfiguredError, 'Synapse OS Agentic pipe is not configured (missing url/user/password or disabled)'
      end

      memo_key = [cfg[:url], cfg[:user], cfg[:password]]
      return @client if defined?(@client) && @client_memo_key == memo_key

      @client_memo_key = memo_key
      @client = Synapseos::AgenticClient.new(base_url: cfg[:url], user: cfg[:user], password: cfg[:password])
    end

    def reset!
      @client = nil
      @client_memo_key = nil
    end

    private

    def read(key)
      env_value = ENV.fetch(key, nil)
      return env_value if env_value.present?

      InstallationConfig.find_by(name: key)&.value
    rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
      nil
    end
  end
end
