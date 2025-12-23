# Copyright 2023 Google LLC
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

require "grpc"
require "googleauth"
require "gapic/grpc/service_stub/rpc_call"

module Gapic
  class ServiceStub
    ##
    # @private
    #
    # Gapic gRPC ServiceStub Channel.
    #
    # This class wraps the gRPC stub object and its RPC methods.
    #
    class Channel
      attr_reader :concurrent_streams

      ##
      # Creates a new Channel instance
      #
      def initialize grpc_stub_class, endpoint:, credentials:, channel_args: nil, interceptors: nil,
                     on_channel_create: nil
        @grpc_stub_class = grpc_stub_class
        @endpoint = endpoint
        @credentials = credentials
        @channel_args = Hash channel_args
        @interceptors = Array interceptors
        @concurrent_streams = 0
        @mutex = Mutex.new
        setup_grpc_stub
        on_channel_create&.call self
      end

      ##
      # Creates a gRPC stub object
      #
      def setup_grpc_stub
        raise ArgumentError, "grpc_stub_class is required" if @grpc_stub_class.nil?
        raise ArgumentError, "endpoint is required" if @endpoint.nil?
        raise ArgumentError, "credentials is required" if @credentials.nil?

        @grpc_stub = case @credentials
                     when ::GRPC::Core::Channel
                       @grpc_stub_class.new @endpoint, nil, channel_override: @credentials, interceptors: @interceptors
                     when ::GRPC::Core::ChannelCredentials, Symbol
                       @grpc_stub_class.new @endpoint, @credentials, channel_args: @channel_args,
                                            interceptors: @interceptors
                     else
                       updater_proc = @credentials.updater_proc if @credentials.respond_to? :updater_proc
                       updater_proc ||= @credentials if @credentials.is_a? Proc
                       raise ArgumentError, "invalid credentials (#{credentials.class})" if updater_proc.nil?

                       call_creds = ::GRPC::Core::CallCredentials.new updater_proc
                       chan_creds = ::GRPC::Core::ChannelCredentials.new.compose call_creds
                       @grpc_stub_class.new @endpoint, chan_creds, channel_args: @channel_args,
                                            interceptors: @interceptors
                     end
      end

      ##
      # Invoke the specified RPC call.
      #
      # @param method_name [Symbol] The RPC method name.
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
      def call_rpc method_name, request, options: nil, &block
        @mutex.synchronize { @concurrent_streams += 1 }
        begin
          rpc_call = RpcCall.new @grpc_stub.method method_name
          response = rpc_call.call request, options: options, &block
          response
        rescue StandardError => e
          raise e
        ensure
          @mutex.synchronize { @concurrent_streams -= 1 }
        end
      end
    end
  end
end
