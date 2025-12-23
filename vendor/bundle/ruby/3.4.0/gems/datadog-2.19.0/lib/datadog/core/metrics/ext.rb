# frozen_string_literal: true

module Datadog
  module Core
    module Metrics
      # @public_api
      module Ext
        DEFAULT_HOST = '127.0.0.1'
        DEFAULT_PORT = 8125

        TAG_LANG = 'language'
        TAG_LANG_INTERPRETER = 'language-interpreter'
        TAG_LANG_VERSION = 'language-version'
        TAG_TRACER_VERSION = 'tracer-version'
      end
    end
  end
end
