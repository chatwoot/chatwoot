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

module Gapic
  module Config
    ##
    # Config::Method is a configuration class that represents the configuration for an API RPC call.
    #
    # @example
    #   require "gapic/config"
    #
    #   class ServiceConfig
    #     extend Gapic::Config
    #
    #     config_attr :host,     "localhost", String
    #     config_attr :port,     443,         Integer
    #     config_attr :timeout,  nil,         Numeric, nil
    #     config_attr :metadata, nil,         Hash, nil
    #
    #     attr_reader :rpc_method
    #
    #     def initialize parent_config = nil
    #       @parent_config = parent_config unless parent_config.nil?
    #       @rpc_method = Gapic::Config::Method.new
    #
    #       yield self if block_given?
    #     end
    #   end
    #
    #   config = ServiceConfig.new
    #
    #   config.timeout = 60
    #   config.rpc_method.timeout = 120
    #
    class Method
      extend Gapic::Config

      config_attr :timeout,      nil, Numeric, nil
      config_attr :metadata,     nil, Hash, nil
      config_attr :retry_policy, nil, Hash, Proc, nil

      ##
      # Create a new Config::Method object instance.
      #
      # @param parent_method [Gapic::Config::Method, nil] The config to look to values for.
      #
      def initialize parent_method = nil
        @parent_config = parent_method unless parent_method.nil?

        yield self if block_given?
      end
    end
  end
end
