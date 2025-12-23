# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "gapic/call_options"
require "grpc/errors"

module Gapic
  class ServiceStub
    class RpcCall
      attr_reader :stub_method

      ##
      # Creates an API object for making a single RPC call.
      #
      # In typical usage, `stub_method` will be a proc used to make an RPC request. This will mostly likely be a bound
      # method from a request Stub used to make an RPC call.
      #
      # The result is created by applying a series of function decorators defined in this module to `stub_method`.
      #
      # The result is another proc which has the same signature as the original.
      #
      # @param stub_method [Proc] Used to make a bare rpc call.
      #
      def initialize stub_method
        @stub_method = stub_method
      end

      ##
      # Invoke the RPC call.
      #
      # @param request [Object] The request object.
      # @param options [Gapic::CallOptions, Hash] The options for making the RPC call. A Hash can be provided to
      #   customize the options object, using keys that match the arguments for {Gapic::CallOptions.new}. This object
      #   should only be used once.
      #
      # @yield [response, operation] Access the response along with the RPC operation.
      # @yieldparam response [Object] The response object.
      # @yieldparam operation [::GRPC::ActiveCall::Operation] The RPC operation for the response.
      #
      # @return [Object] The response object.
      #
      # @example
      #   require "google/showcase/v1beta1/echo_pb"
      #   require "google/showcase/v1beta1/echo_services_pb"
      #   require "gapic"
      #   require "gapic/grpc"
      #
      #   echo_channel = ::GRPC::Core::Channel.new(
      #     "localhost:7469", nil, :this_channel_is_insecure
      #   )
      #   echo_stub = Gapic::ServiceStub.new(
      #     Google::Showcase::V1beta1::Echo::Stub,
      #     endpoint: "localhost:7469", credentials: echo_channel
      #   )
      #   echo_call = Gapic::ServiceStub::RpcCall.new echo_stub.method :echo
      #
      #   request = Google::Showcase::V1beta1::EchoRequest.new
      #   response = echo_call.call request
      #
      # @example Using custom call options:
      #   require "google/showcase/v1beta1/echo_pb"
      #   require "google/showcase/v1beta1/echo_services_pb"
      #   require "gapic"
      #   require "gapic/grpc"
      #
      #   echo_channel = ::GRPC::Core::Channel.new(
      #     "localhost:7469", nil, :this_channel_is_insecure
      #   )
      #   echo_stub = Gapic::ServiceStub.new(
      #     Google::Showcase::V1beta1::Echo::Stub,
      #     endpoint: "localhost:7469", credentials: echo_channel
      #   )
      #   echo_call = Gapic::ServiceStub::RpcCall.new echo_stub.method :echo
      #
      #   request = Google::Showcase::V1beta1::EchoRequest.new
      #   options = Gapic::CallOptions.new(
      #     retry_policy = {
      #       retry_codes: [::GRPC::Core::StatusCodes::UNAVAILABLE]
      #     }
      #   )
      #   response = echo_call.call request, options: options
      #
      # @example Accessing the response and RPC operation using a block:
      #   require "google/showcase/v1beta1/echo_pb"
      #   require "google/showcase/v1beta1/echo_services_pb"
      #   require "gapic"
      #   require "gapic/grpc"
      #
      #   echo_channel = ::GRPC::Core::Channel.new(
      #     "localhost:7469", nil, :this_channel_is_insecure
      #   )
      #   echo_stub = Gapic::ServiceStub.new(
      #     Google::Showcase::V1beta1::Echo::Stub,
      #     endpoint: "localhost:7469", credentials: echo_channel
      #   )
      #   echo_call = Gapic::ServiceStub::RpcCall.new echo_stub.method :echo
      #
      #   request = Google::Showcase::V1beta1::EchoRequest.new
      #   echo_call.call request do |response, operation|
      #     operation.trailing_metadata
      #   end
      #
      def call request, options: nil
        # Converts hash and nil to an options object
        options = Gapic::CallOptions.new(**options.to_h) if options.respond_to? :to_h
        deadline = calculate_deadline options
        metadata = options.metadata

        retried_exception = nil
        begin
          operation = stub_method.call request, deadline: deadline, metadata: metadata, return_op: true
          response = operation.execute
          yield response, operation if block_given?
          response
        rescue ::GRPC::DeadlineExceeded => e
          raise Gapic::GRPC::DeadlineExceededError.new e.message, root_cause: retried_exception
        rescue StandardError => e
          if e.is_a?(::GRPC::Unavailable) && /Signet::AuthorizationError/ =~ e.message
            e = Gapic::GRPC::AuthorizationError.new e.message.gsub(%r{^\d+:}, "")
          end

          if check_retry?(deadline) && options.retry_policy.call(e)
            retried_exception = e
            retry
          end

          raise e
        end
      end

      private

      def calculate_deadline options
        return if options.timeout.nil?
        return if options.timeout.negative?

        Time.now + options.timeout
      end

      def check_retry? deadline
        return true if deadline.nil?

        deadline > Time.now
      end
    end
  end
end
