# Copyright 2014 Google, Inc.
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

require "redis"
require "googleauth/token_store"

module Google
  module Auth
    module Stores
      # Implementation of user token storage backed by Redis. Tokens
      # are stored as JSON using the supplied key, prefixed with
      # `g-user-token:`
      class RedisTokenStore < Google::Auth::TokenStore
        DEFAULT_KEY_PREFIX = "g-user-token:".freeze

        # Create a new store with the supplied redis client.
        #
        # @param [::Redis, String] redis
        #  Initialized redis client to connect to.
        # @param [String] prefix
        #  Prefix for keys in redis. Defaults to 'g-user-token:'
        # @note If no redis instance is provided, a new one is created and
        #  the options passed through. You may include any other keys accepted
        #  by `Redis.new`
        def initialize options = {}
          super()
          redis = options.delete :redis
          prefix = options.delete :prefix
          @redis = case redis
                   when Redis
                     redis
                   else
                     Redis.new options
                   end
          @prefix = prefix || DEFAULT_KEY_PREFIX
        end

        # (see Google::Auth::Stores::TokenStore#load)
        def load id
          key = key_for id
          @redis.get key
        end

        # (see Google::Auth::Stores::TokenStore#store)
        def store id, token
          key = key_for id
          @redis.set key, token
        end

        # (see Google::Auth::Stores::TokenStore#delete)
        def delete id
          key = key_for id
          @redis.del key
        end

        private

        # Generate a redis key from a token ID
        #
        # @param [String] id
        #  ID of the token
        # @return [String]
        #  Redis key
        def key_for id
          @prefix + id
        end
      end
    end
  end
end
