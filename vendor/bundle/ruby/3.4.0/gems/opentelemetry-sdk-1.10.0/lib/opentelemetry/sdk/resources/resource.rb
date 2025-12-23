# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Resources
      # Resource represents a resource, which captures identifying information about the entities
      # for which telemetry (metrics or traces) is reported.
      class Resource
        class << self
          private :new

          # Returns a newly created {Resource} with the specified attributes
          #
          # @param [Hash{String => String, Numeric, Boolean} attributes Hash of key-value pairs to be used
          #   as attributes for this resource
          # @raise [ArgumentError] If attribute keys and values are not strings
          # @return [Resource]
          def create(attributes = {})
            frozen_attributes = attributes.each_with_object({}) do |(k, v), memo|
              raise ArgumentError, 'attribute keys must be strings' unless k.is_a?(String)
              raise ArgumentError, 'attribute values must be (array of) strings, integers, floats, or booleans' unless Internal.valid_value?(v)

              memo[-k] = v.freeze
            end.freeze

            new(frozen_attributes)
          end

          def default
            @default ||= create(SemanticConventions::Resource::SERVICE_NAME => 'unknown_service').merge(process).merge(telemetry_sdk).merge(service_name_from_env)
          end

          def telemetry_sdk
            resource_attributes = {
              SemanticConventions::Resource::TELEMETRY_SDK_NAME => 'opentelemetry',
              SemanticConventions::Resource::TELEMETRY_SDK_LANGUAGE => 'ruby',
              SemanticConventions::Resource::TELEMETRY_SDK_VERSION => OpenTelemetry::SDK::VERSION
            }

            resource_pairs = ENV['OTEL_RESOURCE_ATTRIBUTES']
            return create(resource_attributes) unless resource_pairs.is_a?(String)

            resource_pairs.split(',').each do |pair|
              key, value = pair.split('=')
              resource_attributes[key] = value
            end

            resource_attributes.delete_if { |_key, value| value.nil? || value.empty? }
            create(resource_attributes)
          end

          def process
            resource_attributes = {
              SemanticConventions::Resource::PROCESS_PID => Process.pid,
              SemanticConventions::Resource::PROCESS_COMMAND => $PROGRAM_NAME,
              SemanticConventions::Resource::PROCESS_RUNTIME_NAME => RUBY_ENGINE,
              SemanticConventions::Resource::PROCESS_RUNTIME_VERSION => RUBY_VERSION,
              SemanticConventions::Resource::PROCESS_RUNTIME_DESCRIPTION => RUBY_DESCRIPTION
            }

            create(resource_attributes)
          end

          private

          def service_name_from_env
            service_name = ENV['OTEL_SERVICE_NAME']
            create(SemanticConventions::Resource::SERVICE_NAME => service_name) unless service_name.nil?
          end
        end

        # @api private
        # The constructor is private and only for use internally by the class.
        # Users should use the {create} factory method to obtain a {Resource}
        # instance.
        #
        # @param [Hash<String, String>] frozen_attributes Frozen-hash of frozen-string
        #  key-value pairs to be used as attributes for this resource
        # @return [Resource]
        def initialize(frozen_attributes)
          @attributes = frozen_attributes
        end

        # Returns an enumerator for attributes of this {Resource}
        #
        # @return [Enumerator]
        def attribute_enumerator
          @attribute_enumerator ||= attributes.to_enum
        end

        # Returns a new, merged {Resource} by merging the current {Resource} with
        # the other {Resource}. In case of a collision, the other {Resource}
        # takes precedence
        #
        # @param [Resource] other The other resource to merge
        # @return [Resource] A new resource formed by merging the current resource
        #   with other
        def merge(other)
          return self unless other.is_a?(Resource)

          self.class.send(:new, attributes.merge(other.attributes).freeze)
        end

        protected

        attr_reader :attributes
      end
    end
  end
end
