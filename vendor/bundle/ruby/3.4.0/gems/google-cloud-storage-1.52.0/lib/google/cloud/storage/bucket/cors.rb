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
        # # Bucket Cors
        #
        # A special-case Array for managing the website CORS rules for a bucket.
        # Accessed via {Bucket#cors}.
        #
        # @see https://cloud.google.com/storage/docs/cross-origin Cross-Origin
        #   Resource Sharing (CORS)
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   bucket.cors do |c|
        #     # Remove the last CORS rule from the array
        #     c.pop
        #     # Remove all existing rules with the https protocol
        #     c.delete_if { |r| r.origin.include? "http://example.com" }
        #     c.add_rule ["http://example.org", "https://example.org"],
        #                ["GET", "POST", "DELETE"],
        #                headers: ["X-My-Custom-Header"],
        #                max_age: 3600
        #   end
        #
        # @example Retrieving the bucket's CORS rules.
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #   bucket.cors.size #=> 2
        #   rule = bucket.cors.first
        #   rule.origin #=> ["http://example.org"]
        #   rule.methods #=> ["GET","POST","DELETE"]
        #   rule.headers #=> ["X-My-Custom-Header"]
        #   rule.max_age #=> 3600
        #
        class Cors < DelegateClass(::Array)
          ##
          # @private Initialize a new CORS rules builder with existing CORS
          # rules, if any.
          def initialize rules = []
            super rules
            @original = to_gapi.map(&:to_json)
          end

          # @private
          def changed?
            @original != to_gapi.map(&:to_json)
          end

          ##
          # Add a CORS rule to the CORS rules for a bucket. Accepts options for
          # setting preflight response headers. Preflight requests and responses
          # are required if the request method and headers are not both [simple
          # methods](http://www.w3.org/TR/cors/#simple-method) and [simple
          # headers](http://www.w3.org/TR/cors/#simple-header).
          #
          # @param [String, Array<String>] origin The
          #   [origin](http://tools.ietf.org/html/rfc6454) or origins permitted
          #   for cross origin resource sharing with the bucket. Note: "*" is
          #   permitted in the list of origins, and means "any Origin".
          # @param [String, Array<String>] methods The list of HTTP methods
          #   permitted in cross origin resource sharing with the bucket. (GET,
          #   OPTIONS, POST, etc) Note: "*" is permitted in the list of methods,
          #   and means "any method".
          # @param [String, Array<String>] headers The list of header field
          #   names to send in the Access-Control-Allow-Headers header in the
          #   preflight response. Indicates the custom request headers that may
          #   be used in the actual request.
          # @param [Integer] max_age The value to send in the
          #   Access-Control-Max-Age header in the preflight response. Indicates
          #   how many seconds the results of a preflight request can be cached
          #   in a preflight result cache. The default value is `1800` (30
          #   minutes.)
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.create_bucket "my-bucket" do |b|
          #     b.cors.add_rule ["http://example.org", "https://example.org"],
          #                     "*",
          #                     headers: ["X-My-Custom-Header"],
          #                     max_age: 300
          #   end
          #
          def add_rule origin, methods, headers: nil, max_age: nil
            push Rule.new(origin, methods, headers: headers, max_age: max_age)
          end

          # @private
          def to_gapi
            map(&:to_gapi)
          end

          # @private
          def self.from_gapi gapi_list
            rules = Array(gapi_list).map { |gapi| Rule.from_gapi gapi }
            new rules
          end

          # @private
          def freeze
            each(&:freeze)
            super
          end

          ##
          # # Bucket Cors Rule
          #
          # Represents a website CORS rule for a bucket. Accessed via
          # {Bucket#cors}.
          #
          # @see https://cloud.google.com/storage/docs/cross-origin Cross-Origin
          #   Resource Sharing (CORS)
          #
          # @attr [String] origin The [origin](http://tools.ietf.org/html/rfc6454)
          #   or origins permitted for cross origin resource sharing with the
          #   bucket. Note: "*" is permitted in the list of origins, and means
          #   "any Origin".
          # @attr [String] methods The list of HTTP methods permitted in cross
          #   origin resource sharing with the bucket. (GET, OPTIONS, POST, etc)
          #   Note: "*" is permitted in the list of methods, and means
          #   "any method".
          # @attr [String] headers The list of header field names to send in the
          #   Access-Control-Allow-Headers header in the preflight response.
          #   Indicates the custom request headers that may be used in the
          #   actual request.
          # @attr [String] max_age The value to send in the
          #   Access-Control-Max-Age header in the preflight response. Indicates
          #   how many seconds the results of a preflight request can be cached
          #   in a preflight result cache. The default value is `1800` (30
          #   minutes.)
          #
          # @example Retrieving the bucket's CORS rules.
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #   bucket.cors.size #=> 2
          #   rule = bucket.cors.first
          #   rule.origin #=> ["http://example.org"]
          #   rule.methods #=> ["GET","POST","DELETE"]
          #   rule.headers #=> ["X-My-Custom-Header"]
          #   rule.max_age #=> 3600
          #
          class Rule
            attr_accessor :origin
            attr_accessor :methods
            attr_accessor :headers
            attr_accessor :max_age

            # @private
            def initialize origin, methods, headers: nil, max_age: nil
              @origin = Array(origin)
              @methods = Array(methods)
              @headers = Array(headers)
              @max_age = (max_age || 1800)
            end

            # @private
            def to_gapi
              Google::Apis::StorageV1::Bucket::CorsConfiguration.new(
                origin: Array(origin).dup, http_method: Array(methods).dup,
                response_header: Array(headers).dup, max_age_seconds: max_age
              )
            end

            # @private
            def self.from_gapi gapi
              new gapi.origin.dup, gapi.http_method.dup, \
                  headers: gapi.response_header.dup,
                  max_age: gapi.max_age_seconds
            end

            # @private
            def freeze
              @origin.freeze
              @methods.freeze
              @headers.freeze
              super
            end
          end
        end
      end
    end
  end
end
