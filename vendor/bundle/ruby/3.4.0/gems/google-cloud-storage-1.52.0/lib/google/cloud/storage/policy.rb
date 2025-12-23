# Copyright 2017 Google LLC
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


require "google/cloud/errors"
require "google/apis/storage_v1"
require "google/cloud/storage/policy/bindings"

module Google
  module Cloud
    module Storage
      ##
      # # Policy
      #
      # An abstract Cloud IAM Policy for the Cloud Storage service. See concrete
      # subclasses {Google::Cloud::Storage::PolicyV1} and
      # {Google::Cloud::Storage::PolicyV3}.
      #
      # A common pattern for updating a resource's metadata, such as its Policy,
      # is to read the current data from the service, update the data locally,
      # and then send the modified data for writing. This pattern may result in
      # a conflict if two or more processes attempt the sequence simultaneously.
      # IAM solves this problem with the
      # {Google::Cloud::Storage::Policy#etag} property, which is used to
      # verify whether the policy has changed since the last request. When you
      # make a request to with an `etag` value, Cloud IAM compares the `etag`
      # value in the request with the existing `etag` value associated with the
      # policy. It writes the policy only if the `etag` values match.
      #
      # When you update a policy, first read the policy (and its current `etag`)
      # from the service, then modify the policy locally, and then write the
      # modified policy to the service. See
      # {Google::Cloud::Storage::Bucket#policy} and
      # {Google::Cloud::Storage::Bucket#policy=}.
      #
      # @see https://cloud.google.com/iam/docs/managing-policies Managing
      #   policies
      # @see https://cloud.google.com/storage/docs/json_api/v1/buckets/setIamPolicy
      #   Buckets: setIamPolicy
      #
      # @attr [String] etag Used to verify whether the policy has changed since
      #   the last request. The policy will be written only if the `etag` values
      #   match.
      # @attr [Integer] version The syntax schema version of the policy. Each version
      #   of the policy contains a specific syntax schema that can be used by bindings.
      #   The newer version may contain role bindings with the newer syntax schema
      #   that is unsupported by earlier versions. This field is not intended to
      #   be used for any purposes other than policy syntax schema control.
      #
      #   The following policy versions are valid:
      #
      #   * 1 -  The first version of Cloud IAM policy schema. Supports binding one
      #     role to one or more members. Does not support conditional bindings.
      #   * 3 - Introduces the condition field in the role binding, which further
      #     constrains the role binding via context-based and attribute-based rules.
      #     See [Understanding policies](https://cloud.google.com/iam/docs/policies)
      #     and [Overview of Cloud IAM Conditions](https://cloud.google.com/iam/docs/conditions-overview)
      #     for more information.
      #
      class Policy
        attr_reader :etag
        attr_reader :version

        ##
        # @private Creates a Policy object.
        def initialize etag, version
          @etag = etag
          @version = version
        end
      end

      ##
      # A subclass of {Google::Cloud::Storage::Policy} that supports access to {#roles}
      # and related helpers. Attempts to call {#bindings} and {#version=} will
      # raise a runtime error. To update the Policy version and add bindings with a newer
      # syntax, use {Google::Cloud::Storage::PolicyV3} instead by calling
      # {Google::Cloud::Storage::Bucket#policy} with `requested_policy_version: 3`. To
      # obtain instances of this class, call {Google::Cloud::Storage::Bucket#policy}
      # without the `requested_policy_version` keyword argument.
      #
      # @attr [Hash] roles Returns the version 1 bindings (no conditions) as a hash that
      #   associates roles with arrays of members. See [Understanding
      #   Roles](https://cloud.google.com/iam/docs/understanding-roles) for a
      #   listing of primitive and curated roles. See [Buckets:
      #   setIamPolicy](https://cloud.google.com/storage/docs/json_api/v1/buckets/setIamPolicy)
      #   for a listing of values and patterns for members.
      #
      # @example
      #   require "google/cloud/storage"
      #
      #   storage = Google::Cloud::Storage.new
      #   bucket = storage.bucket "my-bucket"
      #
      #   bucket.policy do |p|
      #     p.version # the value is 1
      #     p.remove "roles/storage.admin", "user:owner@example.com"
      #     p.add "roles/storage.admin", "user:newowner@example.com"
      #     p.roles["roles/storage.objectViewer"] = ["allUsers"]
      #   end
      #
      class PolicyV1 < Policy
        attr_reader :roles

        ##
        # @private Creates a PolicyV1 object.
        def initialize etag, version, roles
          super etag, version
          @roles = roles
        end

        ##
        # Convenience method for adding a member to a binding on this policy.
        # See [Understanding
        # Roles](https://cloud.google.com/iam/docs/understanding-roles) for a
        # listing of primitive and curated roles. See [Buckets:
        # setIamPolicy](https://cloud.google.com/storage/docs/json_api/v1/buckets/setIamPolicy)
        # for a listing of values and patterns for members.
        #
        # @param [String] role_name A Cloud IAM role, such as
        #   `"roles/storage.admin"`.
        # @param [String] member A Cloud IAM identity, such as
        #   `"user:owner@example.com"`.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   bucket.policy do |p|
        #     p.add "roles/storage.admin", "user:newowner@example.com"
        #   end
        #
        def add role_name, member
          role(role_name) << member
        end

        ##
        # Convenience method for removing a member from a binding on this
        # policy. See [Understanding
        # Roles](https://cloud.google.com/iam/docs/understanding-roles) for a
        # listing of primitive and curated roles. See [Buckets:
        # setIamPolicy](https://cloud.google.com/storage/docs/json_api/v1/buckets/setIamPolicy)
        # for a listing of values and patterns for members.
        #
        # @param [String] role_name A Cloud IAM role, such as
        #   `"roles/storage.admin"`.
        # @param [String] member A Cloud IAM identity, such as
        #   `"user:owner@example.com"`.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   bucket.policy do |p|
        #     p.remove "roles/storage.admin", "user:owner@example.com"
        #   end
        #
        def remove role_name, member
          role(role_name).delete member
        end

        ##
        # Convenience method returning the array of members bound to a role in
        # this policy, or an empty array if no value is present for the role in
        # {#roles}. See [Understanding
        # Roles](https://cloud.google.com/iam/docs/understanding-roles) for a
        # listing of primitive and curated roles. See [Buckets:
        # setIamPolicy](https://cloud.google.com/storage/docs/json_api/v1/buckets/setIamPolicy)
        # for a listing of values and patterns for members.
        #
        # @return [Array<String>] The members strings, or an empty array.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   bucket.policy do |p|
        #     p.role("roles/storage.admin") << "user:owner@example.com"
        #   end
        #
        def role role_name
          roles[role_name] ||= []
        end

        ##
        # Returns a deep copy of the policy.
        #
        # @deprecated Because the latest policy is now always retrieved by
        #   {Bucket#policy}.
        #
        # @return [Policy]
        #
        def deep_dup
          warn "DEPRECATED: Storage::PolicyV1#deep_dup"
          dup.tap do |p|
            roles_dup = p.roles.transform_values do |v|
              v.dup rescue value
            end
            p.instance_variable_set :@roles, roles_dup
          end
        end

        ##
        # @private Illegal operation in PolicyV1. Use {#roles} instead.
        #
        # @raise [RuntimeError] If called on this class.
        #
        def bindings
          raise "Illegal operation unless using PolicyV3. Use #roles instead."
        end

        ##
        # @private Illegal operation in PolicyV1. Use {Google::Cloud::Storage::PolicyV3#version=} instead.
        #
        # @raise [RuntimeError] If called on this class.
        #
        def version=(*)
          raise "Illegal operation unless using PolicyV3."
        end

        ##
        # @private Convert the Policy to a
        # Google::Apis::StorageV1::Policy.
        def to_gapi
          Google::Apis::StorageV1::Policy.new(
            etag: etag,
            version: version,
            bindings: roles_to_gapi
          )
        end

        ##
        # @private New Policy from a
        # Google::Apis::StorageV1::Policy object.
        def self.from_gapi gapi
          roles = Array(gapi.bindings).each_with_object({}) do |binding, memo|
            memo[binding.role] = binding.members.to_a
          end
          new gapi.etag, gapi.version, roles
        end

        protected

        def roles_to_gapi
          roles.keys.map do |role_name|
            next if roles[role_name].empty?
            Google::Apis::StorageV1::Policy::Binding.new(
              role: role_name,
              members: roles[role_name].uniq
            )
          end
        end
      end

      ##
      # A subclass of {Google::Cloud::Storage::Policy} that supports access to {#bindings}
      # and {version=}. Attempts to call {#roles} and relate helpers will raise a runtime
      # error. This class may be used to update the Policy version and add bindings with a newer
      # syntax. To obtain instances of this class, call {Google::Cloud::Storage::Bucket#policy}
      # with `requested_policy_version: 3`.
      #
      # @attr [Bindings] bindings Returns the Policy's bindings object that associate roles with
      #   an array of members. Conditions can be configured on the {Binding} object. See
      #   [Understanding Roles](https://cloud.google.com/iam/docs/understanding-roles) for a
      #   listing of primitive and curated roles. See [Buckets:
      #   setIamPolicy](https://cloud.google.com/storage/docs/json_api/v1/buckets/setIamPolicy)
      #   for a listing of values and patterns for members.
      #
      # @example Updating Policy version 1 to version 3:
      #   require "google/cloud/storage"
      #
      #   storage = Google::Cloud::Storage.new
      #   bucket = storage.bucket "my-bucket"
      #
      #   bucket.uniform_bucket_level_access = true
      #
      #   bucket.policy requested_policy_version: 3 do |p|
      #     p.version # the value is 1
      #     p.version = 3
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
      # @example Using Policy version 3:
      #   require "google/cloud/storage"
      #
      #   storage = Google::Cloud::Storage.new
      #   bucket = storage.bucket "my-bucket"
      #
      #   bucket.uniform_bucket_level_access? # true
      #
      #   bucket.policy requested_policy_version: 3 do |p|
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
      class PolicyV3 < Policy
        attr_reader :bindings

        ##
        # @private Creates a PolicyV3 object.
        def initialize etag, version, bindings
          super etag, version
          @bindings = Bindings.new
          @bindings.insert(*bindings)
        end

        ##
        # Updates the syntax schema version of the policy. Each version of the
        # policy contains a specific syntax schema that can be used by bindings.
        # The newer version may contain role bindings with the newer syntax schema
        # that is unsupported by earlier versions. This field is not intended to
        # be used for any purposes other than policy syntax schema control.
        #
        # The following policy versions are valid:
        #
        # * 1 -  The first version of Cloud IAM policy schema. Supports binding one
        #   role to one or more members. Does not support conditional bindings.
        # * 3 - Introduces the condition field in the role binding, which further
        #   constrains the role binding via context-based and attribute-based rules.
        #   See [Understanding policies](https://cloud.google.com/iam/docs/policies)
        #   and [Overview of Cloud IAM Conditions](https://cloud.google.com/iam/docs/conditions-overview)
        #   for more information.
        #
        # @param [Integer] new_version The syntax schema version of the policy.
        #
        # @see https://cloud.google.com/iam/docs/policies#versions Policy versions
        #
        # @example Updating Policy version 1 to version 3:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #   bucket = storage.bucket "my-bucket"
        #
        #   bucket.uniform_bucket_level_access = true
        #
        #   bucket.policy requested_policy_version: 3 do |p|
        #     p.version # the value is 1
        #     p.version = 3
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
        def version= new_version
          if new_version < version
            raise "new_version (#{new_version}) cannot be less than the current version (#{version})."
          end
          @version = new_version
        end

        ##
        # @private Illegal operation in PolicyV3. Use {#bindings} instead.
        #
        # @raise [RuntimeError] If called on this class.
        #
        def roles
          raise "Illegal operation when using PolicyV1. Use Policy#bindings instead."
        end

        ##
        # @private Illegal operation in PolicyV3. Use {#bindings} instead.
        #
        # @raise [RuntimeError] If called on this class.
        #
        def add(*)
          raise "Illegal operation when using PolicyV1. Use Policy#bindings instead."
        end

        ##
        # @private Illegal operation in PolicyV3. Use {#bindings} instead.
        #
        # @raise [RuntimeError] If called on this class.
        #
        def remove(*)
          raise "Illegal operation when using PolicyV1. Use Policy#bindings instead."
        end

        ##
        # @private Illegal operation in PolicyV3. Use {#bindings} instead.
        #
        # @raise [RuntimeError] If called on this class.
        #
        def role(*)
          raise "Illegal operation when using PolicyV1. Use Policy#bindings instead."
        end

        ##
        # @private Illegal operation in PolicyV3. Deprecated in PolicyV1.
        #
        # @raise [RuntimeError] If called on this class.
        #
        def deep_dup
          raise "Illegal operation when using PolicyV3. Deprecated in PolicyV1."
        end

        ##
        # @private Convert the PolicyV3 to a
        # Google::Apis::StorageV1::Policy.
        def to_gapi
          Google::Apis::StorageV1::Policy.new(
            etag: etag,
            version: version,
            bindings: bindings.to_gapi
          )
        end

        ##
        # @private New Policy from a
        # Google::Apis::StorageV1::Policy object.
        def self.from_gapi gapi
          new gapi.etag, gapi.version, Array(gapi.bindings).map(&:to_h)
        end
      end
    end
  end
end
