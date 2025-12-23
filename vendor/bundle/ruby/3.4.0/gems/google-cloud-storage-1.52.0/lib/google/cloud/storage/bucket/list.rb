# Copyright 2015 Google LLC
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
      class Bucket
        ##
        # Bucket::List is a special case Array with additional values.
        class List < DelegateClass(::Array)
          ##
          # If not empty, indicates that there are more buckets
          # that match the request and this value should be passed to
          # the next {Google::Cloud::Storage::Project#buckets} to continue.
          attr_accessor :token

          ##
          # @private Create a new Bucket::List with an array of values.
          def initialize arr = []
            super arr
          end

          ##
          # Whether there is a next page of buckets.
          #
          # @return [Boolean]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   buckets = storage.buckets
          #   if buckets.next?
          #     next_buckets = buckets.next
          #   end
          #
          def next?
            !token.nil?
          end

          ##
          # Retrieve the next page of buckets.
          #
          # @return [Bucket::List]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   buckets = storage.buckets
          #   if buckets.next?
          #     next_buckets = buckets.next
          #   end
          #
          def next
            return nil unless next?
            ensure_service!
            gapi = @service.list_buckets prefix: @prefix, token: @token,
                                         max: @max, user_project: @user_project
            Bucket::List.from_gapi gapi, @service, @prefix, @max,
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
          #   make to load all buckets. Default is no limit.
          # @yield [bucket] The block for accessing each bucket.
          # @yieldparam [Bucket] bucket The bucket object.
          #
          # @return [Enumerator]
          #
          # @example Iterating each bucket by passing a block:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   buckets = storage.buckets
          #   buckets.all do |bucket|
          #     puts bucket.name
          #   end
          #
          # @example Using the enumerator by not passing a block:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   buckets = storage.buckets
          #   all_names = buckets.all.map do |bucket|
          #     bucket.name
          #   end
          #
          # @example Limit the number of API calls made:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   buckets = storage.buckets
          #   buckets.all(request_limit: 10) do |bucket|
          #     puts bucket.name
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
          # @private New Bucket::List from a Google API Client
          # Google::Apis::StorageV1::Buckets object.
          def self.from_gapi gapi_list, service, prefix = nil, max = nil,
                             user_project: nil
            buckets = new(Array(gapi_list.items).map do |gapi_object|
              Bucket.from_gapi gapi_object, service, user_project: user_project
            end)
            buckets.instance_variable_set :@token, gapi_list.next_page_token
            buckets.instance_variable_set :@service, service
            buckets.instance_variable_set :@prefix, prefix
            buckets.instance_variable_set :@max, max
            buckets.instance_variable_set :@user_project, user_project
            buckets
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
