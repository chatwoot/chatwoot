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

require "gapic/operation/retry_policy"
require "google/protobuf/well_known_types"
require "gapic/common/version"

module Gapic
  # A collection of common header values.
  module Headers
    ##
    # @param ruby_version [String] The ruby version. Defaults to `RUBY_VERSION`.
    # @param lib_name [String] The client library name.
    # @param lib_version [String] The client library version.
    # @param gax_version [String] The Gapic version. Defaults to `Gapic::Common::VERSION`.
    # @param gapic_version [String] The Gapic version.
    # @param grpc_version [String] The GRPC version. Defaults to `::GRPC::VERSION`.
    # @param rest_version [String] The Rest Library (Faraday) version. Defaults to `Faraday::VERSION`.
    # @param transports_version_send [Array] Which transports to send versions for.
    #   Allowed values to contain are:
    #     `:grpc` to send the GRPC library version (if defined)
    #     `:rest` to send the REST library version (if defined)
    #   Defaults to `[:grpc]`
    def self.x_goog_api_client ruby_version: nil, lib_name: nil, lib_version: nil, gax_version: nil,
                               gapic_version: nil, grpc_version: nil, rest_version: nil, protobuf_version: nil,
                               transports_version_send: [:grpc]

      ruby_version ||= ::RUBY_VERSION
      gax_version  ||= ::Gapic::Common::VERSION
      grpc_version ||= ::GRPC::VERSION if defined? ::GRPC::VERSION
      rest_version ||= ::Faraday::VERSION if defined? ::Faraday::VERSION
      protobuf_version ||= Gem.loaded_specs["google-protobuf"].version.to_s if Gem.loaded_specs.key? "google-protobuf"

      x_goog_api_client_header = ["gl-ruby/#{ruby_version}"]
      x_goog_api_client_header << "#{lib_name}/#{lib_version}" if lib_name
      x_goog_api_client_header << "gax/#{gax_version}"
      x_goog_api_client_header << "gapic/#{gapic_version}" if gapic_version
      x_goog_api_client_header << "grpc/#{grpc_version}" if grpc_version && transports_version_send.include?(:grpc)
      x_goog_api_client_header << "rest/#{rest_version}" if rest_version && transports_version_send.include?(:rest)
      x_goog_api_client_header << "pb/#{protobuf_version}" if protobuf_version
      x_goog_api_client_header.join " ".freeze
    end
  end
end
