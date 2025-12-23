# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Memcache
    module Prepend
      extend Helper

      module_function

      def client_prepender(client_class)
        Module.new do
          extend Helper
          include NewRelic::Agent::Instrumentation::Memcache::Tracer

          supported_methods_for(client_class, client_methods).each do |method_name|
            define_method method_name do |*args, &block|
              with_newrelic_tracing(method_name, *args) { super(*args, &block) }
            end
          end
        end
      end

      def dalli_cas_prependers
        yield(::Dalli::Client, dalli_client_prepender(dalli_cas_methods))
        yield(::Dalli::Client, dalli_get_multi_prepender(:get_multi_cas))
      end

      def dalli_prependers
        if supports_datastore_instances?
          yield(::Dalli::Client, dalli_client_prepender(dalli_methods))
          yield(::Dalli::Client, dalli_get_multi_prepender(:get_multi))

          if supports_binary_protocol?
            yield(::Dalli::Protocol::Binary, dalli_server_prepender)
          else
            yield(::Dalli::Server, dalli_server_prepender)
          end

          yield(::Dalli::Ring, dalli_ring_prepender)
        else
          yield(::Dalli::Client, dalli_client_prepender(client_methods))
        end
      end

      def dalli_client_prepender(supported_methods)
        Module.new do
          extend Helper
          include NewRelic::Agent::Instrumentation::Memcache::Tracer

          supported_methods.each do |method_name|
            define_method method_name do |*args, &block|
              with_newrelic_tracing(method_name, *args) { super(*args, &block) }
            end
          end
        end
      end

      def dalli_get_multi_prepender(method_name)
        Module.new do
          extend Helper
          include NewRelic::Agent::Instrumentation::Memcache::Tracer

          define_method method_name do |*args, &block|
            get_multi_with_newrelic_tracing(method_name) { super(*args, &block) }
          end
        end
      end

      def dalli_ring_prepender
        Module.new do
          extend Helper
          include NewRelic::Agent::Instrumentation::Memcache::Tracer

          def server_for_key(key)
            server_for_key_with_newrelic_tracing { super }
          end
        end
      end

      def dalli_server_prepender
        Module.new do
          extend Helper
          include NewRelic::Agent::Instrumentation::Memcache::Tracer

          # TODO: MAJOR VERSION
          # Dalli - 3.1.0 renamed send_multiget to pipelined_get, but the method is otherwise the same
          # Once we no longer support Dalli < 3.1.0, remove this conditional logic
          if Gem::Version.new(::Dalli::VERSION) >= Gem::Version.new('3.1.0')
            def pipelined_get(keys)
              send_multiget_with_newrelic_tracing(keys) { super }
            end
          else
            def send_multiget(keys)
              send_multiget_with_newrelic_tracing(keys) { super }
            end
          end
        end
      end
    end
  end
end
