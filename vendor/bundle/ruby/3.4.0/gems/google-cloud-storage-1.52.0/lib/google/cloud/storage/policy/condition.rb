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


module Google
  module Cloud
    module Storage
      class Policy
        ##
        # # Condition
        #
        # Value object accepting an attribute-based logic expression based on a
        # subset of the Common Expression Language (CEL).
        #
        # @see https://cloud.google.com/iam/docs/conditions-overview Cloud IAM
        #   policies with conditions
        #
        # @attr [String] title Used to identify the condition. Required.
        # @attr [String] description Used to document the condition. Optional.
        # @attr [String] expression Defines an attribute-based logic
        #   expression using a subset of the Common Expression Language (CEL).
        #   The condition expression can contain multiple statements, each uses
        #   one attributes, and statements are combined using logic operators,
        #   following CEL language specification. Required.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #   bucket = storage.bucket "my-bucket"
        #
        #   policy = bucket.policy requested_policy_version: 3
        #   policy.bindings.each do |binding|
        #     puts binding.condition.title if binding.condition
        #   end
        #
        # @example Updating a Policy from version 1 to version 3 by adding a condition:
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
        class Condition
          attr_reader :title
          attr_reader :description
          attr_reader :expression

          ##
          # Creates a Condition object.
          #
          # @param [String] title Used to identify the condition. Required.
          # @param [String] description Used to document the condition. Optional.
          # @param [String] expression Defines an attribute-based logic
          #   expression using a subset of the Common Expression Language (CEL).
          #   The condition expression can contain multiple statements, each uses
          #   one attributes, and statements are combined using logic operators,
          #   following CEL language specification. Required.
          #
          def initialize title:, expression:, description: nil
            @title = String title
            @description = String description
            @expression = String expression
          end

          ##
          # The title used to identify the condition. Required.
          #
          # @param [String] new_title The new title.
          #
          def title= new_title
            @title = String new_title
          end

          ##
          # The description to document the condition. Optional.
          #
          # @param [String] new_description The new description.
          #
          def description= new_description
            @description = String new_description
          end

          ##
          # An attribute-based logic expression using a subset of the Common
          # Expression Language (CEL). The condition expression can contain
          # multiple statements, each uses one attributes, and statements are
          # combined using logic operators, following CEL language
          # specification. Required.
          #
          # @see https://cloud.google.com/iam/docs/conditions-overview CEL for conditions
          #
          # @param [String] new_expression The new expression.
          #
          def expression= new_expression
            @expression = String new_expression
          end

          def to_gapi
            {
              title: @title,
              description: @description,
              expression: @expression
            }.delete_if { |_, v| v.nil? }
          end
        end
      end
    end
  end
end
