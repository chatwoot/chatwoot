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

require "grpc"
require "googleauth"
require "gapic/grpc/service_stub/rpc_call"
require "gapic/grpc/service_stub/channel"
require "gapic/grpc/service_stub/channel_pool"


module Gapic
  ##
  # Gapic gRPC Stub
  #
  # This class wraps the actual gRPC Stub and ChannelPool objects.
  #
  # @!attribute [r] grpc_stub
  #   @return [Object] The instance of the gRPC stub class (`grpc_stub_class`) constructor argument.
  # @!attribute [r] channel_pool
  #   @return [Gapic::ServiceStub::ChannelPool] The instance of the ChannelPool class.
  #
  class ServiceStub
    attr_reader :grpc_stub
    attr_reader :channel_pool

    ##
    # Creates a Gapic gRPC stub object.
    #
    # @param grpc_stub_class [Class] gRPC stub class to create a new instance of.
    # @param endpoint [String] The endpoint of the API.
    # @param credentials [Google::Auth::Credentials, Signet::OAuth2::Client, String, Hash, Proc,
    #   ::GRPC::Core::Channel, ::GRPC::Core::ChannelCredentials] Provides the means for authenticating requests made by
    #   the client. This parameter can be many types:
    #
    #   * A `Google::Auth::Credentials` uses a the properties of its represented keyfile for authenticating requests
    #     made by this client.
    #   * A `Signet::OAuth2::Client` object used to apply the OAuth credentials.
    #   * A `::GRPC::Core::Channel` will be used to make calls through.
    #   * A `::GRPC::Core::ChannelCredentials` for the setting up the RPC client. The channel credentials should
    #     already be composed with a `::GRPC::Core::CallCredentials` object.
    #   * A `Proc` will be used as an updater_proc for the Grpc channel. The proc transforms the metadata for
    #     requests, generally, to give OAuth credentials.
    # @param channel_args [Hash] The channel arguments. (This argument is ignored when `credentials` is
    #     provided as a `::GRPC::Core::Channel`.)
    # @param interceptors [Array<::GRPC::ClientInterceptor>] An array of {::GRPC::ClientInterceptor} objects that will
    #   be used for intercepting calls before they are executed Interceptors are an EXPERIMENTAL API.
    # @param channel_pool_config [::Gapic::ServiceStub:ChannelPool::Configuration] The configuration for channel
    #     pool. This argument will raise error when `credentials` is provided as a `::GRPC::Core::Channel`.
    #
    def initialize grpc_stub_class, endpoint:, credentials:, channel_args: nil,
                   interceptors: nil, channel_pool_config: nil
      raise ArgumentError, "grpc_stub_class is required" if grpc_stub_class.nil?
      raise ArgumentError, "endpoint is required" if endpoint.nil?
      raise ArgumentError, "credentials is required" if credentials.nil?

      @channel_pool = nil
      @grpc_stub = nil
      channel_args = Hash channel_args
      interceptors = Array interceptors


      if channel_pool_config && channel_pool_config.channel_count > 1
        create_channel_pool grpc_stub_class, endpoint: endpoint, credentials: credentials,
                            channel_args: channel_args, interceptors: interceptors,
                            channel_pool_config: channel_pool_config
      else
        create_grpc_stub grpc_stub_class, endpoint: endpoint, credentials: credentials,
                         channel_args: channel_args, interceptors: interceptors
      end
    end

    def create_channel_pool grpc_stub_class, endpoint:, credentials:, channel_args: nil,
                            interceptors: nil, channel_pool_config: nil
      if credentials.is_a? ::GRPC::Core::Channel
        raise ArgumentError, "Cannot create a channel pool with GRPC::Core::Channel as credentials"
      end
      @channel_pool = ChannelPool.new grpc_stub_class, endpoint: endpoint, credentials: credentials,
                        channel_args: channel_args, interceptors: interceptors,
                        config: channel_pool_config
    end

    def create_grpc_stub grpc_stub_class, endpoint:, credentials:, channel_args: nil, interceptors: nil
      @grpc_stub = case credentials
                   when ::GRPC::Core::Channel
                     grpc_stub_class.new endpoint, nil, channel_override: credentials,
                                         interceptors: interceptors
                   when ::GRPC::Core::ChannelCredentials, Symbol
                     grpc_stub_class.new endpoint, credentials, channel_args: channel_args,
                                         interceptors: interceptors
                   else
                     updater_proc = credentials.updater_proc if credentials.respond_to? :updater_proc
                     updater_proc ||= credentials if credentials.is_a? Proc
                     raise ArgumentError, "invalid credentials (#{credentials.class})" if updater_proc.nil?

                     call_creds = ::GRPC::Core::CallCredentials.new updater_proc
                     chan_creds = ::GRPC::Core::ChannelCredentials.new.compose call_creds
                     grpc_stub_class.new endpoint, chan_creds, channel_args: channel_args,
                                         interceptors: interceptors
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
    #
    #   request = Google::Showcase::V1beta1::EchoRequest.new
    #   response = echo_stub.call_rpc :echo, request
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
    #
    #   request = Google::Showcase::V1beta1::EchoRequest.new
    #   options = Gapic::CallOptions.new(
    #     retry_policy = {
    #       retry_codes: [::GRPC::Core::StatusCodes::UNAVAILABLE]
    #     }
    #   )
    #   response = echo_stub.call_rpc :echo, request
    #                                 options: options
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
    #
    #   request = Google::Showcase::V1beta1::EchoRequest.new
    #   echo_stub.call_rpc :echo, request do |response, operation|
    #     operation.trailing_metadata
    #   end
    #
    def call_rpc method_name, request, options: nil, &block
      if @channel_pool.nil?
        rpc_call = RpcCall.new @grpc_stub.method method_name
        rpc_call.call request, options: options, &block
      else
        @channel_pool.call_rpc method_name, request, options: options, &block
      end
    end
  end
end
