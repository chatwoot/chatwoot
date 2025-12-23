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


require "google/cloud/storage/policy/binding"

module Google
  module Cloud
    module Storage
      class Policy
        ##
        # # Bindings
        #
        # Enumerable object for managing Cloud IAM bindings associated with
        # a bucket.
        #
        # @see https://cloud.google.com/iam/docs/overview Cloud IAM Overview
        #
        # @example Updating a Policy from version 1 to version 3:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #   bucket = storage.bucket "my-bucket"
        #
        #   bucket.uniform_bucket_level_access = true
        #
        #   bucket.policy requested_policy_version: 3 do |p|
        #     p.version # the value is 1
        #     p.version = 3 # Must be explicitly set to opt-in to support for conditions.
        #
        #     expr = "resource.name.startsWith(\"projects/_/buckets/bucket-name/objects/prefix-a-\")"
        #     p.bindings.insert({
        #                         role: "roles/storage.admin",
        #                         members: ["user:owner@example.com"],
        #                         condition: {
        #                           title: "my-condition",
        #                           description: "description of condition",
        #                           expression: expr
        #                         }
        #                       })
        #   end
        #
        class Bindings
          include Enumerable

          ##
          # @private Creates a Bindings object.
          def initialize
            @bindings = []
          end

          ##
          # Adds a binding or bindings to the collection. The arguments may be
          # {Google::Cloud::Storage::Policy::Binding} objects or equivalent hash
          # objects that will be implicitly coerced to binding objects.
          #
          # @param [Google::Cloud::Storage::Policy::Binding, Hash] bindings One
          #   or more bindings to be added to the policy owning the collection.
          #   The arguments may be {Google::Cloud::Storage::Policy::Binding}
          #   objects or equivalent hash objects that will be implicitly coerced
          #   to binding objects.
          #
          # @return [Bindings] `self` for chaining.
          #
          # @example Updating a Policy from version 1 to version 3:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.uniform_bucket_level_access = true
          #
          #   bucket.policy requested_policy_version: 3 do |p|
          #     p.version # the value is 1
          #     p.version = 3 # Must be explicitly set to opt-in to support for conditions.
          #
          #     expr = "resource.name.startsWith(\"projects/_/buckets/bucket-name/objects/prefix-a-\")"
          #     p.bindings.insert({
          #                         role: "roles/storage.admin",
          #                         members: ["user:owner@example.com"],
          #                         condition: {
          #                           title: "my-condition",
          #                           description: "description of condition",
          #                           expression: expr
          #                         }
          #                       })
          #   end
          #
          def insert *bindings
            bindings = coerce_bindings(*bindings)
            @bindings += bindings
            self
          end

          ##
          # Deletes the binding or bindings from the collection that are equal to
          # the arguments. The specification arguments may be
          # {Google::Cloud::Storage::Policy::Binding} objects or equivalent hash
          # objects that will be implicitly coerced to binding objects.
          #
          # @param [Google::Cloud::Storage::Policy::Binding, Hash] bindings One
          #   or more specifications for bindings to be removed from the
          #   collection. The arguments may be
          #   {Google::Cloud::Storage::Policy::Binding} objects or equivalent
          #   hash objects that will be implicitly coerced to binding objects.
          #
          # @return [Bindings] `self` for chaining.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.policy requested_policy_version: 3 do |p|
          #     expr = "resource.name.startsWith(\"projects/_/buckets/bucket-name/objects/prefix-a-\")"
          #     p.bindings.remove({
          #                         role: "roles/storage.admin",
          #                         members: ["user:owner@example.com"],
          #                         condition: {
          #                           title: "my-condition",
          #                           description: "description of condition",
          #                           expression: expr
          #                         }
          #                       })
          #   end
          #
          def remove *bindings
            bindings = coerce_bindings(*bindings)
            @bindings -= bindings
            self
          end

          ##
          # Calls the block once for each binding in the collection, passing
          # a {Google::Cloud::Storage::Policy::Binding} object as parameter. A
          # {Google::Cloud::Storage::Policy::Binding} object is passed even
          # when the arguments to {#insert} were hash objects.
          #
          # If no block is given, an enumerator is returned instead.
          #
          # @yield [binding] A binding in this bindings collection.
          # @yieldparam [Google::Cloud::Storage::Policy::Binding] binding A
          #   binding object, even when the arguments to {#insert} were hash
          #   objects.
          #
          # @return [Enumerator]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #   bucket = storage.bucket "my-bucket"
          #
          #   policy = bucket.policy requested_policy_version: 3
          #   policy.bindings.each do |binding|
          #     puts binding.role
          #   end
          #
          def each &block
            return enum_for :each unless block_given?

            @bindings.each(&block)
          end

          ##
          # @private
          def to_gapi
            @bindings.map(&:to_gapi)
          end

          protected

          def coerce_bindings *bindings
            bindings.map do |binding|
              binding = Binding.new(**binding) if binding.is_a? Hash
              raise ArgumentError, "expected Binding, not #{binding.inspect}" unless binding.is_a? Binding
              binding
            end
          end
        end
      end
    end
  end
end
