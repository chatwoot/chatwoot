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


require "delegate"

module Google
  module Cloud
    module Storage
      class HmacKey
        ##
        # HmacKey::List is a special case Array with additional values.
        class List < DelegateClass(::Array)
          ##
          # If not empty, indicates that there are more HMAC keys
          # that match the request and this value should be passed to
          # the next {Google::Cloud::Storage::Project#hmac_keys} to continue.
          attr_accessor :token

          ##
          # @private Create a new HmacKey::List with an array of values.
          def initialize arr = []
            super arr
          end

          ##
          # Whether there is a next page of HMAC keys.
          #
          # @return [Boolean]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   hmac_keys = storage.hmac_keys
          #   if hmac_keys.next?
          #     next_hmac_keys = hmac_keys.next
          #   end
          #
          def next?
            !token.nil?
          end

          ##
          # Retrieve the next page of HMAC keys.
          #
          # @return [HmacKey::List]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   hmac_keys = storage.hmac_keys
          #   if hmac_keys.next?
          #     next_hmac_keys = hmac_keys.next
          #   end
          #
          def next
            return nil unless next?
            ensure_service!
            gapi = @service.list_hmac_keys \
              service_account_email: @service_account_email,
              show_deleted_keys: @show_deleted_keys, token: @token, max: @max,
              user_project: @user_project

            HmacKey::List.from_gapi \
              gapi, @service,
              service_account_email: @service_account_email,
              show_deleted_keys: @show_deleted_keys, max: @max,
              user_project: @user_project
          end

          ##
          # Retrieves remaining results by repeatedly invoking {#next} until
          # {#next?} returns `false`. Calls the given block once for each
          # result, which is passed as the argument to the block.
          #
          # An Enumerator is returned if no block is given.
          #
          # This method will make repeated API calls until all remaining results
          # are retrieved. (Unlike `#each`, for example, which merely iterates
          # over the results returned by a single API call.) Use with caution.
          #
          # @param [Integer] request_limit The upper limit of API requests to
          #   make to load all HMAC keys. Default is no limit.
          # @yield [key] The block for accessing each HMAC key.
          # @yieldparam [HmacKey] key The HMAC key object.
          #
          # @return [Enumerator]
          #
          # @example Iterating each HMAC key by passing a block:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   hmac_keys = storage.hmac_keys
          #   hmac_keys.all do |key|
          #     puts key.access_id
          #   end
          #
          # @example Using the enumerator by not passing a block:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   hmac_keys = storage.hmac_keys
          #   all_names = hmac_keys.all.map do |key|
          #     key.access_id
          #   end
          #
          # @example Limit the number of API calls made:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   hmac_keys = storage.hmac_keys
          #   hmac_keys.all(request_limit: 10) do |key|
          #     puts key.access_id
          #   end
          #
          def all request_limit: nil, &block
            request_limit = request_limit.to_i if request_limit
            unless block_given?
              return enum_for :all, request_limit: request_limit
            end
            results = self
            loop do
              results.each(&block)
              if request_limit
                request_limit -= 1
                break if request_limit.negative?
              end
              break unless results.next?
              results = results.next
            end
          end

          ##
          # @private New HmacKey::List from a Google API Client
          # Google::Apis::StorageV1::HmacKeysMetadata object.
          def self.from_gapi gapi_list, service, service_account_email: nil,
                             show_deleted_keys: nil, max: nil, user_project: nil
            hmac_keys = new(Array(gapi_list.items).map do |gapi_object|
              HmacKey.from_gapi_metadata gapi_object, service,
                                         user_project: user_project
            end)
            hmac_keys.instance_variable_set :@token, gapi_list.next_page_token
            hmac_keys.instance_variable_set :@service, service
            hmac_keys.instance_variable_set :@service_account_email,
                                            service_account_email
            hmac_keys.instance_variable_set :@show_deleted_keys,
                                            show_deleted_keys
            hmac_keys.instance_variable_set :@max, max
            hmac_keys.instance_variable_set :@user_project, user_project
            hmac_keys
          end

          protected

          ##
          # Raise an error unless an active connection is available.
          def ensure_service!
            raise "Must have active connection" unless @service
          end
        end
      end
    end
  end
end
