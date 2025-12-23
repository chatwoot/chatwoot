# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module GRPC
        module Formatting
          VALUE_UNKNOWN = 'unknown'

          # A class to extract GRPC span attributes from the GRPC implementing class method object.
          class MethodObjectFormatter
            # grpc_full_method is a string containing all the rpc method information (from the Protobuf definition)
            # in a single string with the following format: /$package.$service/$method
            attr_reader :grpc_full_method

            # legacy_grpc_service is built using the Ruby GRPC service implementation package and class name instead
            # of the rpc interface representation from Protobuf. It's kept for compatibility.
            attr_reader :legacy_grpc_service

            # legacy_grpc_method is built using the Ruby GRPC service implementation method name instead of the rpc
            # interface representation from Protobuf. It's kept for compatibility.
            attr_reader :legacy_grpc_method

            # resource_name is used for the span resource name.
            attr_reader :resource_name

            def initialize(grpc_method_object)
              @grpc_full_method = format_full_method(grpc_method_object)
              @resource_name = format_resource_name(grpc_method_object)
              @legacy_grpc_method = extract_legacy_grpc_method(grpc_method_object)
              @legacy_grpc_service = extract_legacy_grpc_service(grpc_method_object)
            end

            private

            def format_full_method(grpc_method_object)
              service = extract_grpc_service(grpc_method_object)
              method = extract_grpc_method(grpc_method_object)
              "/#{service}/#{method}"
            end

            def extract_grpc_service(grpc_method_object)
              owner = grpc_method_object.owner
              return VALUE_UNKNOWN unless owner.instance_variable_defined?(:@service_name)

              # Ruby protoc generated code includes this variable which directly contains the value from the original
              # protobuf definition
              owner.service_name.to_s
            end

            # extract_grpc_method attempts to find the original method name from the Protobuf file definition,
            # since grpc gem forces the implementation method name to be in snake_case.
            def extract_grpc_method(grpc_method_object)
              owner = grpc_method_object.owner

              return VALUE_UNKNOWN unless owner.instance_variable_defined?(:@rpc_descs)

              method, = owner.rpc_descs.find do |k, _|
                ::GRPC::GenericService.underscore(k.to_s) == grpc_method_object.name.to_s
              end

              return VALUE_UNKNOWN if method.nil?

              method.to_s
            end

            def extract_legacy_grpc_service(grpc_method_object)
              grpc_method_object.owner.to_s
            end

            def extract_legacy_grpc_method(grpc_method_object)
              grpc_method_object.name
            end

            def format_resource_name(grpc_method_object)
              grpc_method_object
                .owner
                .to_s
                .downcase
                .split('::')
                .<<(grpc_method_object.name)
                .join('.')
            end
          end

          # A class to extract GRPC span attributes from the full method string.
          class FullMethodStringFormatter
            # grpc_full_method is a string containing all the rpc method information (from the Protobuf definition)
            # in a single string with the following format: /$package.$service/$method
            attr_reader :grpc_full_method

            # resource_name is used for the span resource name.
            attr_reader :resource_name

            # rpc_service represents the $package.$service part of the grpc_full_method string.
            attr_reader :rpc_service

            def initialize(grpc_full_method)
              @grpc_full_method = grpc_full_method
              @resource_name = format_resource_name(grpc_full_method)
              @rpc_service = extract_grpc_service(grpc_full_method)
            end

            private

            def format_resource_name(grpc_full_method)
              grpc_full_method
                .downcase
                .split('/')
                .reject(&:empty?)
                .join('.')
            end

            def extract_grpc_service(grpc_full_method)
              parts = grpc_full_method.split('/')
              if parts.length < 3
                ''
              else
                parts[1]
              end
            end
          end
        end
      end
    end
  end
end
