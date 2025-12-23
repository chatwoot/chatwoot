# frozen_string_literal: true

require_relative '../../../datadog/version'

module Datadog
  module Core
    module Environment
      # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
      module Ext
        # e.g for CRuby '3.0.1', for JRuby '9.2.19.0', for TruffleRuby '21.1.0'
        ENGINE_VERSION = if defined?(RUBY_ENGINE_VERSION)
          RUBY_ENGINE_VERSION
        else
          # CRuby < 2.3 doesn't support RUBY_ENGINE_VERSION
          RUBY_VERSION
        end

        ENV_API_KEY = 'DD_API_KEY'
        ENV_ENVIRONMENT = 'DD_ENV'
        ENV_SERVICE = 'DD_SERVICE'
        ENV_OTEL_SERVICE = 'OTEL_SERVICE_NAME'
        ENV_SITE = 'DD_SITE'
        ENV_TAGS = 'DD_TAGS'
        ENV_OTEL_RESOURCE_ATTRIBUTES = 'OTEL_RESOURCE_ATTRIBUTES'
        ENV_VERSION = 'DD_VERSION'
        FALLBACK_SERVICE_NAME =
          begin
            File.basename($PROGRAM_NAME, '.*')
          rescue
            'ruby'
          end.freeze

        LANG = 'ruby'
        LANG_ENGINE = RUBY_ENGINE
        LANG_INTERPRETER = "#{RUBY_ENGINE}-#{RUBY_PLATFORM}"
        LANG_PLATFORM = RUBY_PLATFORM
        LANG_VERSION = RUBY_VERSION
        RUBY_ENGINE = ::RUBY_ENGINE # e.g. 'ruby', 'jruby', 'truffleruby'
        TAG_ENV = 'env'
        TAG_SERVICE = 'service'
        TAG_VERSION = 'version'

        GEM_DATADOG_VERSION = Datadog::VERSION::STRING
      end
    end
  end
end
