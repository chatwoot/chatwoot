# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic::Agent::Instrumentation
  module Curb
    module Chain
      def self.instrument! # rubocop:disable Metrics/AbcSize
        Curl::Easy.class_eval do
          include NewRelic::Agent::Instrumentation::Curb::Easy

          def http_head_with_newrelic(*args, &blk)
            http_head_with_tracing { http_head_without_newrelic(*args, &blk) }
          end

          alias_method(:http_head_without_newrelic, :http_head)
          alias_method(:http_head, :http_head_with_newrelic)

          def http_post_with_newrelic(*args, &blk)
            http_post_with_tracing { http_post_without_newrelic(*args, &blk) }
          end

          alias_method(:http_post_without_newrelic, :http_post)
          alias_method(:http_post, :http_post_with_newrelic)

          def http_put_with_newrelic(*args, &blk)
            http_put_with_tracing { http_put_without_newrelic(*args, &blk) }
          end

          alias_method(:http_put_without_newrelic, :http_put)
          alias_method(:http_put, :http_put_with_newrelic)

          # Hook the #http method to set the verb.
          def http_with_newrelic(verb)
            http_with_tracing(verb) { http_without_newrelic(verb) }
          end

          alias_method(:http_without_newrelic, :http)
          alias_method(:http, :http_with_newrelic)

          # Hook the #perform method to mark the request as non-parallel.
          def perform_with_newrelic
            perform_with_tracing { perform_without_newrelic }
          end

          alias_method(:perform_without_newrelic, :perform)
          alias_method(:perform, :perform_with_newrelic)

          # Record the HTTP verb for future #perform calls
          def method_with_newrelic(verb)
            method_with_tracing(verb) { method_without_newrelic(verb) }
          end

          alias_method(:method_without_newrelic, :method)
          alias_method(:method, :method_with_newrelic)

          # We override this method in order to ensure access to header_str even
          # though we use an on_header callback
          def header_str_with_newrelic
            header_str_with_tracing { header_str_without_newrelic }
          end

          alias_method(:header_str_without_newrelic, :header_str)
          alias_method(:header_str, :header_str_with_newrelic)
        end

        Curl::Multi.class_eval do
          include NewRelic::Agent::Instrumentation::Curb::Multi

          # Add CAT with callbacks if the request is serial
          def add_with_newrelic(curl)
            add_with_tracing(curl) { add_without_newrelic(curl) }
          end

          alias_method(:add_without_newrelic, :add)
          alias_method(:add, :add_with_newrelic)

          # Trace as an External/Multiple call if the first request isn't serial.
          def perform_with_newrelic(&blk)
            perform_with_tracing { perform_without_newrelic(&blk) }
          end

          alias_method(:perform_without_newrelic, :perform)
          alias_method(:perform, :perform_with_newrelic)
        end
      end
    end
  end
end
