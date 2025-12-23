# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module Memcache
        module Dalli
          extend Helper

          module_function

          def instrument!
            if supports_datastore_instances?
              instrument_methods(::Dalli::Client, dalli_methods)
              instrument_multi_method(:get_multi)
              instrument_send_multiget
              instrument_server_for_key
            else
              instrument_methods(::Dalli::Client, client_methods)
            end
          end

          def instrument_multi_method(method_name)
            visibility = NewRelic::Helper.instance_method_visibility(::Dalli::Client, method_name)
            method_name_without = :"#{method_name}_without_newrelic_trace"

            ::Dalli::Client.class_eval do
              alias_method(method_name_without, method_name)

              define_method(method_name) do |*args, &block|
                get_multi_with_newrelic_tracing(method_name) { __send__(method_name_without, *args, &block) }
              end

              __send__(visibility, method_name)
              __send__(visibility, method_name_without)
            end
          end

          def instrument_server_for_key
            ::Dalli::Ring.class_eval do
              include NewRelic::Agent::Instrumentation::Memcache::Tracer

              alias_method(:server_for_key_without_newrelic_trace, :server_for_key)

              def server_for_key(key)
                server_for_key_with_newrelic_tracing { server_for_key_without_newrelic_trace(key) }
              end
            end
          end

          def instrument_send_multiget
            if supports_binary_protocol?
              ::Dalli::Protocol::Binary
            else
              ::Dalli::Server
            end.class_eval do
              include NewRelic::Agent::Instrumentation::Memcache::Tracer

              # TODO: MAJOR VERSION
              # Dalli - 3.1.0 renamed send_multiget to pipelined_get, but the method is otherwise the same
              # Once we no longer support Dalli < 3.1.0, remove this conditional logic
              if Gem::Version.new(::Dalli::VERSION) >= Gem::Version.new('3.1.0')
                alias_method(:pipelined_get_without_newrelic_trace, :pipelined_get)
                def pipelined_get(keys)
                  send_multiget_with_newrelic_tracing(keys) { pipelined_get_without_newrelic_trace(keys) }
                end
              else
                alias_method(:send_multiget_without_newrelic_trace, :send_multiget)
                def send_multiget(keys)
                  send_multiget_with_newrelic_tracing(keys) { send_multiget_without_newrelic_trace(keys) }
                end
              end
            end
          end
        end

        module DalliCAS
          extend Dalli
          extend Helper

          module_function

          def should_instrument?
            supported_methods_for(::Dalli::Client, dalli_cas_methods).any?
          end

          def instrument!
            instrument_methods(::Dalli::Client, dalli_cas_methods)
            instrument_multi_method(:get_multi_cas)
          end
        end
      end
    end
  end
end
