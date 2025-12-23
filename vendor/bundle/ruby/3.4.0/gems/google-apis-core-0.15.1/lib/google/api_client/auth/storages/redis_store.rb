# Copyright 2013 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'json'

module Google
  class APIClient
    # @deprecated Use google-auth-library-ruby instead
    class RedisStore

      DEFAULT_REDIS_CREDENTIALS_KEY = "google_api_credentials"

      attr_accessor :redis

      ##
      # Initializes the RedisStore object.
      #
      # @param [Object] redis
      #  Redis instance
      # @param [Object] key
      #  Optional key to store credentials under. Defaults to 'google_api_credentials'
      def initialize(redis, key = nil)
        @redis= redis
        @redis_credentials_key = key
      end

      ##
      # Attempt to read in credentials from redis.
      # @return [Hash]
      def load_credentials
        credentials = redis.get redis_credentials_key
        JSON.parse(credentials) if credentials
      end

      def redis_credentials_key
        @redis_credentials_key || DEFAULT_REDIS_CREDENTIALS_KEY
      end

      ##
      # Write the credentials to redis.
      #
      # @param [Hash] credentials_hash
      def write_credentials(credentials_hash)
        redis.set(redis_credentials_key, credentials_hash.to_json)
      end
    end
  end
end
