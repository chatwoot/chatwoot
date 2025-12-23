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


require "google/cloud/storage/policy/condition"

module Google
  module Cloud
    module Storage
      class Policy
        ##
        # # Binding
        #
        # Value object associating members and an optional condition with a role.
        #
        # @see https://cloud.google.com/iam/docs/overview Cloud IAM Overview
        #
        # @attr [String] role Role that is assigned to members. For example,
        #   `roles/viewer`, `roles/editor`, or `roles/owner`. Required.
        # @attr [Array<String>] members Specifies the identities requesting
        #   access for a Cloud Platform resource. members can have the
        #   following values. Required.
        #
        #   * `allUsers`: A special identifier that represents anyone who is on
        #     the internet; with or without a Google account.
        #   * `allAuthenticatedUsers`: A special identifier that represents
        #      anyone who is authenticated with a Google account or a service
        #      account.
        #   * `user:{emailid}`: An email address that represents a specific
        #     Google account. For example, `alice@example.com`.
        #   * `serviceAccount:{emailid}`: An email address that represents a
        #     service account. For example, `my-other-app@appspot.gserviceaccount.com`.
        #   * `group:{emailid}`: An email address that represents a Google group.
        #     For example, `admins@example.com`.
        #   * `domain:{domain}`: The G Suite domain (primary) that represents
        #     all the users of that domain. For example, `google.com` or
        #     `example.com`. Required.
        #
        # @attr [Google::Cloud::Storage::Policy::Condition, nil] condition The
        #   condition that is associated with this binding, or `nil` if there is
        #   no condition. NOTE: An unsatisfied condition will not allow user
        #   access via current binding. Different bindings, including their
        #   conditions, are examined independently.
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
        class Binding
          attr_reader :role
          attr_reader :members
          attr_reader :condition

          ##
          # Creates a Binding object.
          #
          # @param [String] role Role that is assigned to members. For example,
          #   `roles/viewer`, `roles/editor`, or `roles/owner`. Required.
          # @param [Array<String>] members Specifies the identities requesting
          #   access for a Cloud Platform resource. members can have the
          #   following values. Required.
          #
          #   * `allUsers`: A special identifier that represents anyone who is on
          #     the internet; with or without a Google account.
          #   * `allAuthenticatedUsers`: A special identifier that represents
          #      anyone who is authenticated with a Google account or a service
          #      account.
          #   * `user:{emailid}`: An email address that represents a specific
          #     Google account. For example, `alice@example.com`.
          #   * `serviceAccount:{emailid}`: An email address that represents a
          #     service account. For example, `my-other-app@appspot.gserviceaccount.com`.
          #   * `group:{emailid}`: An email address that represents a Google group.
          #     For example, `admins@example.com`.
          #   * `domain:{domain}`: The G Suite domain (primary) that represents
          #     all the users of that domain. For example, `google.com` or
          #     `example.com`. Required.
          #
          # @param [Google::Cloud::Storage::Policy::Condition] condition The
          #   condition that is associated with this binding. NOTE: An unsatisfied
          #   condition will not allow user access via current binding. Different
          #   bindings, including their conditions, are examined independently.
          #   Optional.
          #
          def initialize role:, members:, condition: nil
            @role = String role

            @members = Array members
            raise ArgumentError, "members is empty, must be provided" if @members.empty?

            condition = Condition.new(**condition) if condition.is_a? Hash
            if condition && !(condition.is_a? Condition)
              raise ArgumentError, "expected Condition, not #{condition.inspect}"
            end
            @condition = condition
          end

          ##
          # Sets the role for the binding.
          #
          # @param [String] new_role Role that is assigned to members. For example,
          #   `roles/viewer`, `roles/editor`, or `roles/owner`. Required.
          #
          def role= new_role
            @role = String new_role
          end

          ##
          # Sets the members for the binding.
          #
          # @param [Array<String>] new_members Specifies the identities requesting
          #   access for a Cloud Platform resource. members can have the
          #   following values. Required.
          #
          #   * `allUsers`: A special identifier that represents anyone who is on
          #     the internet; with or without a Google account.
          #   * `allAuthenticatedUsers`: A special identifier that represents
          #      anyone who is authenticated with a Google account or a service
          #      account.
          #   * `user:{emailid}`: An email address that represents a specific
          #     Google account. For example, `alice@example.com`.
          #   * `serviceAccount:{emailid}`: An email address that represents a
          #     service account. For example, `my-other-app@appspot.gserviceaccount.com`.
          #   * `group:{emailid}`: An email address that represents a Google group.
          #     For example, `admins@example.com`.
          #   * `domain:{domain}`: The G Suite domain (primary) that represents
          #     all the users of that domain. For example, `google.com` or
          #     `example.com`. Required.
          #
          def members= new_members
            new_members = Array new_members
            raise ArgumentError, "members is empty, must be provided" if new_members.empty?
            @members = new_members
          end

          ##
          # Sets the condition for the binding.
          #
          # @param [Google::Cloud::Storage::Policy::Condition] new_condition The
          #   condition that is associated with this binding. NOTE: An unsatisfied
          #   condition will not allow user access via current binding. Different
          #   bindings, including their conditions, are examined independently.
          #   Optional.
          # @overload condition=(title:, description: nil, expression:)
          #   @param [String] title Used to identify the condition. Required.
          #   @param [String] description Used to document the condition. Optional.
          #   @param [String] expression Defines an attribute-based logic
          #     expression using a subset of the Common Expression Language (CEL).
          #     The condition expression can contain multiple statements, each uses
          #     one attributes, and statements are combined using logic operators,
          #     following CEL language specification. Required.
          #
          def condition= new_condition
            new_condition = Condition.new(**new_condition) if new_condition.is_a? Hash
            if new_condition && !new_condition.is_a?(Condition)
              raise ArgumentError, "expected Condition, not #{new_condition.inspect}"
            end
            @condition = new_condition
          end

          ##
          # @private
          def <=> other
            return nil unless other.is_a? Binding

            ret = role <=> other.role
            return ret unless ret.zero?
            ret = members <=> other.members
            return ret unless ret.zero?
            condition&.to_gapi <=> other.condition&.to_gapi
          end

          ##
          # @private
          def eql? other
            role.eql?(other.role) &&
              members.eql?(other.members) &&
              condition&.to_gapi.eql?(other.condition&.to_gapi)
          end

          ##
          # @private
          def hash
            [
              @role,
              @members,
              @condition&.to_gapi
            ].hash
          end

          ##
          # @private
          def to_gapi
            params = {
              role: @role,
              members: @members,
              condition: @condition&.to_gapi
            }.delete_if { |_, v| v.nil? }
            Google::Apis::StorageV1::Policy::Binding.new(**params)
          end
        end
      end
    end
  end
end
