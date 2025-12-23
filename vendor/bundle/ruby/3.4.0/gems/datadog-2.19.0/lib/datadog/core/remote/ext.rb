# frozen_string_literal: true

module Datadog
  module Core
    module Remote
      module Ext
        ENV_ENABLED = 'DD_REMOTE_CONFIGURATION_ENABLED'
        ENV_POLL_INTERVAL_SECONDS = 'DD_REMOTE_CONFIG_POLL_INTERVAL_SECONDS'
        ENV_BOOT_TIMEOUT_SECONDS = 'DD_REMOTE_CONFIG_BOOT_TIMEOUT_SECONDS'
      end
    end
  end
end
