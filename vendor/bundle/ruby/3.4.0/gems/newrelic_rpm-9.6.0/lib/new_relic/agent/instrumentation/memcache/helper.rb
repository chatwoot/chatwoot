# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Memcache
    module Helper
      DATASTORE_INSTANCES_SUPPORTED_VERSION = Gem::Version.new('2.6.4')
      BINARY_PROTOCOL_SUPPORTED_VERSION = Gem::Version.new('3.0.2')

      def supports_datastore_instances?
        DATASTORE_INSTANCES_SUPPORTED_VERSION <= Gem::Version.new(::Dalli::VERSION)
      end

      def supports_binary_protocol?
        BINARY_PROTOCOL_SUPPORTED_VERSION <= Gem::Version.new(::Dalli::VERSION)
      end

      def client_methods
        [:get, :get_multi, :set, :add, :incr, :decr, :delete, :replace, :append,
          :prepend, :cas, :single_get, :multi_get, :single_cas, :multi_cas]
      end

      def dalli_methods
        [:get, :set, :add, :incr, :decr, :delete, :replace, :append, :prepend, :cas]
      end

      def dalli_cas_methods
        [:get_cas, :set_cas, :replace_cas, :delete_cas]
      end

      def supported_methods_for(client_class, methods)
        methods.select do |method_name|
          client_class.method_defined?(method_name) || client_class.private_method_defined?(method_name)
        end
      end

      def instrument_methods(client_class, requested_methods = METHODS)
        supported_methods_for(client_class, requested_methods).each do |method_name|
          visibility = NewRelic::Helper.instance_method_visibility(client_class, method_name)
          method_name_without = :"#{method_name}_without_newrelic_trace"

          client_class.class_eval do
            include NewRelic::Agent::Instrumentation::Memcache::Tracer

            alias_method(method_name_without, method_name)

            define_method(method_name) do |*args, &block|
              with_newrelic_tracing(method_name, *args) { __send__(method_name_without, *args, &block) }
            end

            __send__(visibility, method_name)
            __send__(visibility, method_name_without)
          end
        end
      end
    end
  end
end
