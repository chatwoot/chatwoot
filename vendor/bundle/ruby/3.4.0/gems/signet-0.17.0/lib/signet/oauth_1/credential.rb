# Copyright (C) 2010 Google Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

module Signet # :nodoc:
  module OAuth1
    class Credential
      ##
      # Creates a token object from a key and secret.
      #
      # @example
      #   Signet::OAuth1::Credential.new(
      #     :key => "dpf43f3p2l4k3l03",
      #     :secret => "kd94hf93k423kf44"
      #   )
      #
      # @example
      #   Signet::OAuth1::Credential.new([
      #     ["oauth_token", "dpf43f3p2l4k3l03"],
      #     ["oauth_token_secret", "kd94hf93k423kf44"]
      #   ])
      #
      # @example
      #   Signet::OAuth1::Credential.new(
      #     "dpf43f3p2l4k3l03", "kd94hf93k423kf44"
      #   )
      def initialize *args
        # We want to be particularly flexible in how we initialize a token
        # object for maximum interoperability.  However, this flexibility
        # means we need to be careful about returning an unexpected value for
        # key or secret to avoid difficult-to-debug situations.  Thus lots
        # of type-checking.

        # This is cheaper than coercing to some kind of Hash with
        # indifferent access.  Also uglier.
        key_from_hash = lambda do |parameters|
          parameters["oauth_token"] ||
            parameters[:oauth_token] ||
            parameters["key"] ||
            parameters[:key]
        end
        secret_from_hash = lambda do |parameters|
          parameters["oauth_token_secret"] ||
            parameters[:oauth_token_secret] ||
            parameters["secret"] ||
            parameters[:secret]
        end
        if args.first.respond_to? :to_hash
          parameters = args.first.to_hash
          @key = key_from_hash.call parameters
          @secret = secret_from_hash.call parameters
          unless @key && @secret
            raise ArgumentError,
                  "Could not find both key and secret in #{hash.inspect}."
          end
        else
          # Normalize to an Array
          if !args.first.is_a?(String) &&
             !args.first.respond_to?(:to_str) &&
             args.first.is_a?(Enumerable)
            # We need to special-case strings since they're technically
            # Enumerable objects.
            args = args.first.to_a
          elsif args.first.respond_to? :to_ary
            args = args.first.to_ary
          end
          if args.all? { |value| value.is_a? Array }
            parameters = args.each_with_object({}) { |(k, v), h| h[k] = v; }
            @key = key_from_hash.call parameters
            @secret = secret_from_hash.call parameters
          elsif args.size == 2
            @key, @secret = args
          else
            raise ArgumentError,
                  "wrong number of arguments (#{args.size} for 2)"
          end
        end
        raise TypeError, "Expected String, got #{@key.class}." unless @key.respond_to? :to_str
        @key = @key.to_str
        raise TypeError, "Expected String, got #{@secret.class}." unless @secret.respond_to? :to_str
        @secret = @secret.to_str
      end

      attr_accessor :key
      attr_accessor :secret

      def to_hash
        {
          "oauth_token"        => key,
          "oauth_token_secret" => secret
        }
      end
      alias to_h to_hash

      def == other
        if other.respond_to?(:key) && other.respond_to?(:secret)
          key == other.key && secret == other.secret
        else
          false
        end
      end
    end
  end
end
