# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'json'
require 'new_relic/agent/new_relic_service/marshaller'

module NewRelic
  module Agent
    class NewRelicService
      # Marshal collector protocol with JSON when available
      class JsonMarshaller < Marshaller
        def initialize
          warn_for_yajl
        end

        OK_YAJL_VERSION = Gem::Version.new('1.2.1')

        def warn_for_yajl
          if defined?(::Yajl)
            require 'yajl/version'
            if Gem::Version.new(::Yajl::VERSION) < OK_YAJL_VERSION
              ::NewRelic::Agent.logger.warn("Detected yajl-ruby version #{::Yajl::VERSION} which can cause segfaults with newrelic_rpm's thread profiling features. We strongly recommend you upgrade to the latest yajl-ruby version available.")
            end
          end
        rescue => err
          ::NewRelic::Agent.logger.warn('Failed trying to watch for problematic yajl-ruby version.', err)
        end

        def dump(ruby, opts = {})
          prepared = prepare(ruby, opts)

          if !opts[:skip_normalization] && Agent.config[:normalize_json_string_encodings]
            prepared = NewRelic::Agent::EncodingNormalizer.normalize_object(prepared)
          end

          ::JSON.dump(prepared)
        end

        def load(data)
          if data.nil? || data.empty?
            return nil
          end

          return_value(::JSON.load(data))
        rescue => e
          ::NewRelic::Agent.logger.debug("#{e.class.name} : #{e.message} encountered loading collector response: #{data}")
          raise
        end

        def default_encoder
          if NewRelic::Agent.config[:simple_compression]
            Encoders::Identity
          else
            Encoders::Base64CompressedJSON
          end
        end

        def format
          'json'
        end

        def self.human_readable?
          true # for some definitions of 'human'
        end
      end
    end
  end
end
