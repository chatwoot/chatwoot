# Copyright 2015 Google, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "googleauth/signet"
require "googleauth/credentials_loader"
require "multi_json"

module Google
  module Auth
    ##
    # Small utility for normalizing scopes into canonical form.
    #
    # The canonical form of scopes is as an array of strings, each in the form
    # of a full URL. This utility converts space-delimited scope strings into
    # this form, and handles a small number of common aliases.
    #
    # This is used by UserRefreshCredentials to verify that a credential grants
    # a requested scope.
    #
    module ScopeUtil
      ##
      # Aliases understood by this utility
      #
      ALIASES = {
        "email"   => "https://www.googleapis.com/auth/userinfo.email",
        "profile" => "https://www.googleapis.com/auth/userinfo.profile",
        "openid"  => "https://www.googleapis.com/auth/plus.me"
      }.freeze

      ##
      # Normalize the input, which may be an array of scopes or a whitespace-
      # delimited scope string. The output is always an array, even if a single
      # scope is input.
      #
      # @param scope [String,Array<String>] Input scope(s)
      # @return [Array<String>] An array of scopes in canonical form.
      #
      def self.normalize scope
        list = as_array scope
        list.map { |item| ALIASES[item] || item }
      end

      ##
      # Ensure the input is an array. If a single string is passed in, splits
      # it via whitespace. Does not interpret aliases.
      #
      # @param scope [String,Array<String>] Input scope(s)
      # @return [Array<String>] Always an array of strings
      # @raise ArgumentError If the input is not a string or array of strings
      #
      def self.as_array scope
        case scope
        when Array
          scope.each do |item|
            unless item.is_a? String
              raise ArgumentError, "Invalid scope value: #{item.inspect}. Must be string or array"
            end
          end
          scope
        when String
          scope.split
        else
          raise ArgumentError, "Invalid scope value: #{scope.inspect}. Must be string or array"
        end
      end
    end
  end
end
