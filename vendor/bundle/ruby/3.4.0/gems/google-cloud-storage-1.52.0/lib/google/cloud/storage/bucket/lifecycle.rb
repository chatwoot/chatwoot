# Copyright 2018 Google LLC
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
require "google/cloud/storage/convert"

module Google
  module Cloud
    module Storage
      class Bucket
        ##
        # # Bucket Lifecycle
        #
        # A special-case Array for managing the Object Lifecycle Management
        # rules for a bucket. Accessed via {Bucket#lifecycle}.
        #
        # @see https://cloud.google.com/storage/docs/lifecycle Object
        #   Lifecycle Management
        # @see https://cloud.google.com/storage/docs/managing-lifecycles
        #   Managing Object Lifecycles
        #
        # @example Specifying the lifecycle management rules for a new bucket.
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.create_bucket "my-bucket" do |b|
        #     b.lifecycle.add_set_storage_class_rule "COLDLINE", age: 10
        #     b.lifecycle.add_delete_rule age: 30, is_live: false
        #   end
        #
        # @example Retrieving a bucket's lifecycle management rules.
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #   bucket = storage.bucket "my-bucket"
        #
        #   bucket.lifecycle.size #=> 2
        #   rule = bucket.lifecycle.first
        #   rule.action #=> "SetStorageClass"
        #   rule.storage_class #=> "COLDLINE"
        #   rule.age #=> 10
        #   rule.matches_storage_class #=> ["STANDARD", "NEARLINE"]
        #   rule.matches_prefix #=> ["myprefix/foo"]
        #   rule.matches_suffix #=> [".jpg", ".png"]
        #
        # @example Updating the bucket's lifecycle management rules in a block.
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #   bucket = storage.bucket "my-bucket"
        #
        #   bucket.lifecycle do |l|
        #     # Remove the last rule from the array
        #     l.pop
        #     # Remove all rules with the given condition
        #     l.delete_if do |r|
        #       r.matches_storage_class.include? "NEARLINE"
        #     end
        #     l.add_set_storage_class_rule "COLDLINE", age: 10, is_live: true
        #     l.add_delete_rule age: 30, is_live: false
        #   end
        #
        class Lifecycle < DelegateClass(::Array)
          include Convert
          ##
          # @private Initialize a new lifecycle rules builder with existing
          # lifecycle rules, if any.
          def initialize rules = []
            super rules
            @original = to_gapi.rule.map(&:to_json)
          end

          # @private
          def changed?
            @original != to_gapi.rule.map(&:to_json)
          end

          ##
          # Adds a SetStorageClass lifecycle rule to the Object Lifecycle
          # Management rules for a bucket.
          #
          # @see https://cloud.google.com/storage/docs/lifecycle Object
          #   Lifecycle Management
          # @see https://cloud.google.com/storage/docs/managing-lifecycles
          #   Managing Object Lifecycles
          #
          # @param [String,Symbol] storage_class The target storage class.
          #   Required if the type of the action is `SetStorageClass`. The
          #   argument will be converted from symbols and lower-case to
          #   upper-case strings.
          # @param [Integer] age The age of a file (in days). This condition is
          #   satisfied when a file reaches the specified age.
          # @param [String,Date] created_before A date in RFC 3339 format with
          #   only the date part (for instance, "2013-01-15"). This condition is
          #   satisfied when a file is created before midnight of the specified
          #   date in UTC.
          # @param [String,Date] custom_time_before A date in RFC 3339 format with
          #   only the date part (for instance, "2013-01-15"). This condition is
          #   satisfied when the custom time on an object is before this date in UTC.
          # @param [Integer] days_since_custom_time Represents the number of
          #   days elapsed since the user-specified timestamp set on an object.
          #   The condition is satisfied if the days elapsed is at least this
          #   number. If no custom timestamp is specified on an object, the
          #   condition does not apply.
          # @param [Integer] days_since_noncurrent_time Represents the number of
          #   days elapsed since the noncurrent timestamp of an object. The
          #   condition is satisfied if the days elapsed is at least this number.
          #   The value of the field must be a nonnegative integer. If it's zero,
          #   the object version will become eligible for Lifecycle action as
          #   soon as it becomes noncurrent. Relevant only for versioning-enabled
          #   buckets. (See {Bucket#versioning?})
          # @param [Boolean] is_live Relevant only for versioned files. If the
          #   value is `true`, this condition matches live files; if the value
          #   is `false`, it matches archived files.
          # @param [String,Symbol,Array<String,Symbol>] matches_storage_class
          #   Files having any of the storage classes specified by this
          #   condition will be matched. Values include `STANDARD`, `NEARLINE`,
          #   `COLDLINE`, and `ARCHIVE`. `REGIONAL`,`MULTI_REGIONAL`, and
          #   `DURABLE_REDUCED_AVAILABILITY` are supported as legacy storage
          #   classes. Arguments will be converted from symbols and lower-case
          #   to upper-case strings.
          # @param [String,Date] noncurrent_time_before A date in RFC 3339 format
          #   with only the date part (for instance, "2013-01-15"). This condition
          #   is satisfied when the noncurrent time on an object is before this
          #   date in UTC. This condition is relevant only for versioned objects.
          # @param [Integer] num_newer_versions Relevant only for versioned
          #   files. If the value is N, this condition is satisfied when there
          #   are at least N versions (including the live version) newer than
          #   this version of the file.
          # @param [Array<String,Symbol>] matches_prefix
          #  Files having their name with the specified list of prefixs will be matched.
          #  Arguments will be converted from symbols to strings.
          # @param [Array<String,Symbol>] matches_suffix
          #  Files having their name with the specified list of suffixes will be matched.
          #  Arguments will be converted from symbols to strings.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.create_bucket "my-bucket" do |b|
          #     b.lifecycle.add_set_storage_class_rule "COLDLINE", age: 10
          #   end
          #
          def add_set_storage_class_rule storage_class,
                                         age: nil,
                                         created_before: nil,
                                         custom_time_before: nil,
                                         days_since_custom_time: nil,
                                         days_since_noncurrent_time: nil,
                                         is_live: nil,
                                         matches_storage_class: nil,
                                         noncurrent_time_before: nil,
                                         num_newer_versions: nil,
                                         matches_prefix: nil,
                                         matches_suffix: nil
            push Rule.new(
              "SetStorageClass",
              storage_class: storage_class_for(storage_class),
              age: age,
              created_before: created_before,
              custom_time_before: custom_time_before,
              days_since_custom_time: days_since_custom_time,
              days_since_noncurrent_time: days_since_noncurrent_time,
              is_live: is_live,
              matches_storage_class: storage_class_for(matches_storage_class),
              noncurrent_time_before: noncurrent_time_before,
              num_newer_versions: num_newer_versions,
              matches_prefix: Array(matches_prefix),
              matches_suffix: Array(matches_suffix)
            )
          end

          ##
          # Adds a Delete lifecycle rule to the Object Lifecycle
          # Management rules for a bucket.
          #
          # @see https://cloud.google.com/storage/docs/lifecycle Object
          #   Lifecycle Management
          # @see https://cloud.google.com/storage/docs/managing-lifecycles
          #   Managing Object Lifecycles
          #
          # @param [Integer] age The age of a file (in days). This condition is
          #   satisfied when a file reaches the specified age.
          # @param [String,Date] created_before A date in RFC 3339 format with
          #   only the date part (for instance, "2013-01-15"). This condition is
          #   satisfied when a file is created before midnight of the specified
          #   date in UTC.
          # @param [String,Date] custom_time_before A date in RFC 3339 format with
          #   only the date part (for instance, "2013-01-15"). This condition is
          #   satisfied when the custom time on an object is before this date in UTC.
          # @param [Integer] days_since_custom_time Represents the number of
          #   days elapsed since the user-specified timestamp set on an object.
          #   The condition is satisfied if the days elapsed is at least this
          #   number. If no custom timestamp is specified on an object, the
          #   condition does not apply.
          # @param [Integer] days_since_noncurrent_time Represents the number of
          #   days elapsed since the noncurrent timestamp of an object. The
          #   condition is satisfied if the days elapsed is at least this number.
          #   The value of the field must be a nonnegative integer. If it's zero,
          #   the object version will become eligible for Lifecycle action as
          #   soon as it becomes noncurrent. Relevant only for versioning-enabled
          #   buckets. (See {Bucket#versioning?})
          # @param [Boolean] is_live Relevant only for versioned files. If the
          #   value is `true`, this condition matches live files; if the value
          #   is `false`, it matches archived files.
          # @param [String,Symbol,Array<String,Symbol>] matches_storage_class
          #   Files having any of the storage classes specified by this
          #   condition will be matched. Values include `STANDARD`, `NEARLINE`,
          #   `COLDLINE`, and `ARCHIVE`. `REGIONAL`,`MULTI_REGIONAL`, and
          #   `DURABLE_REDUCED_AVAILABILITY` are supported as legacy storage
          #   classes. Arguments will be converted from symbols and lower-case
          #   to upper-case strings.
          # @param [String,Date] noncurrent_time_before A date in RFC 3339 format
          #   with only the date part (for instance, "2013-01-15"). This condition
          #   is satisfied when the noncurrent time on an object is before this
          #   date in UTC. This condition is relevant only for versioned objects.
          # @param [Integer] num_newer_versions Relevant only for versioned
          #   files. If the value is N, this condition is satisfied when there
          #   are at least N versions (including the live version) newer than
          #   this version of the file.
          # @param [Array<String,Symbol>] matches_prefix
          #  Files having their name with the specified list of prefixs will be matched.
          #  Arguments will be converted from symbols to strings.
          # @param [Array<String,Symbol>] matches_suffix
          #  Files having their name with the specified list of suffixes will be matched.
          #  Arguments will be converted from symbols to strings.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.create_bucket "my-bucket" do |b|
          #     b.lifecycle.add_delete_rule age: 30, is_live: false
          #   end
          #
          def add_delete_rule age: nil,
                              created_before: nil,
                              custom_time_before: nil,
                              days_since_custom_time: nil,
                              days_since_noncurrent_time: nil,
                              is_live: nil,
                              matches_storage_class: nil,
                              noncurrent_time_before: nil,
                              num_newer_versions: nil,
                              matches_prefix: nil,
                              matches_suffix: nil
            push Rule.new(
              "Delete",
              age: age,
              created_before: created_before,
              custom_time_before: custom_time_before,
              days_since_custom_time: days_since_custom_time,
              days_since_noncurrent_time: days_since_noncurrent_time,
              is_live: is_live,
              matches_storage_class: storage_class_for(matches_storage_class),
              noncurrent_time_before: noncurrent_time_before,
              num_newer_versions: num_newer_versions,
              matches_prefix: Array(matches_prefix),
              matches_suffix: Array(matches_suffix)
            )
          end

          ##
          # Adds a AbortIncompleteMultipartUpload lifecycle rule to the Object Lifecycle
          # Management rules for a bucket.
          #
          # @see https://cloud.google.com/storage/docs/lifecycle Object
          #   Lifecycle Management
          # @see https://cloud.google.com/storage/docs/managing-lifecycles
          #   Managing Object Lifecycles
          #
          # @param [Integer] age The age of a file (in days). This condition is
          #   satisfied when a file reaches the specified age.
          # @param [Array<String,Symbol>] matches_prefix
          #  Files having their name with the specified list of prefixs will be matched.
          #  Arguments will be converted from symbols to strings.
          # @param [Array<String,Symbol>] matches_suffix
          #  Files having their name with the specified list of suffixes will be matched.
          #  Arguments will be converted from symbols to strings.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.create_bucket "my-bucket" do |b|
          #     b.lifecycle.add_abort_incomplete_multipart_upload_rule age: 10,
          #                                                            matches_prefix: ["images/"],
          #                                                            matches_suffix: [".pdf"]
          #   end
          #
          def add_abort_incomplete_multipart_upload_rule age: nil,
                                                         matches_prefix: nil,
                                                         matches_suffix: nil
            push Rule.new(
              "AbortIncompleteMultipartUpload",
              age: age,
              matches_prefix: Array(matches_prefix),
              matches_suffix: Array(matches_suffix)
            )
          end

          # @private
          def to_gapi
            Google::Apis::StorageV1::Bucket::Lifecycle.new(
              rule: map(&:to_gapi)
            )
          end

          # @private
          def self.from_gapi gapi
            gapi_list = gapi.rule if gapi
            rules = Array(gapi_list).map do |rule_gapi|
              Rule.from_gapi rule_gapi
            end
            new rules
          end

          # @private
          def freeze
            each(&:freeze)
            super
          end

          ##
          # # Bucket Lifecycle Rule
          #
          # Represents an Object Lifecycle Management rule for a bucket. The
          # action for the rule will be taken when its conditions are met.
          # Accessed via {Bucket#lifecycle}.
          #
          # @see https://cloud.google.com/storage/docs/lifecycle Object
          #   Lifecycle Management
          # @see https://cloud.google.com/storage/docs/managing-lifecycles
          #   Managing Object Lifecycles
          #
          # @attr [String] action The type of action taken when the rule's
          #   conditions are met. Currently, only `Delete` and `SetStorageClass`
          #   are supported.
          # @attr [String] storage_class The target storage class for the
          #   action. Required only if the action is `SetStorageClass`.
          # @attr [Integer] age The age of a file (in days). This condition is
          #   satisfied when a file reaches the specified age.
          # @attr [String,Date,nil] created_before A date in RFC 3339 format with
          #   only the date part (for instance, "2013-01-15"). This condition is
          #   satisfied when a file is created before midnight of the specified
          #   date in UTC. When returned by the service, a non-empty value will
          #   always be a Date object.
          # @attr [String,Date,nil] custom_time_before A date in RFC 3339 format with
          #   only the date part (for instance, "2013-01-15"). This condition is
          #   satisfied when the custom time on an object is before this date in UTC.
          # @attr [Integer,nil] days_since_custom_time Represents the number of
          #   days elapsed since the user-specified timestamp set on an object.
          #   The condition is satisfied if the days elapsed is at least this
          #   number. If no custom timestamp is specified on an object, the
          #   condition does not apply.
          # @attr [Integer] days_since_noncurrent_time Represents the number of
          #   days elapsed since the noncurrent timestamp of an object. The
          #   condition is satisfied if the days elapsed is at least this number.
          #   The value of the field must be a nonnegative integer. If it's zero,
          #   the object version will become eligible for Lifecycle action as
          #   soon as it becomes noncurrent. Relevant only for versioning-enabled
          #   buckets. (See {Bucket#versioning?})
          # @attr [Boolean] is_live Relevant only for versioned files. If the
          #   value is `true`, this condition matches live files; if the value
          #   is `false`, it matches archived files.
          # @attr [Array<String>] matches_storage_class Files having any of the
          #   storage classes specified by this condition will be matched.
          #   Values include `STANDARD`, `NEARLINE`, `COLDLINE`, and `ARCHIVE`.
          #   `REGIONAL`, `MULTI_REGIONAL`, and `DURABLE_REDUCED_AVAILABILITY`
          #   are supported as legacy storage classes.
          # @attr [String,Date,nil] noncurrent_time_before A date in RFC 3339 format
          #   with only the date part (for instance, "2013-01-15"). This condition
          #   is satisfied when the noncurrent time on an object is before this
          #   date in UTC. This condition is relevant only for versioned objects.
          #   When returned by the service, a non-empty value will always be a
          #   Date object.
          # @attr [Integer] num_newer_versions Relevant only for versioned
          #   files. If the value is N, this condition is satisfied when there
          #   are at least N versions (including the live version) newer than
          #   this version of the file.
          #
          # @example Retrieving a bucket's lifecycle management rules.
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.lifecycle.size #=> 2
          #   rule = bucket.lifecycle.first
          #   rule.action #=> "SetStorageClass"
          #   rule.storage_class #=> "COLDLINE"
          #   rule.age #=> 10
          #   rule.matches_storage_class #=> ["STANDARD", "NEARLINE"]
          #   rule.matches_prefix #=> ["myprefix/foo"]
          #   rule.matches_suffix #=> [".jpg", ".png"]
          #
          # @example Updating the bucket's lifecycle rules in a block.
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.update do |b|
          #     b.lifecycle do |l|
          #       # Remove the last rule from the array
          #       l.pop
          #       # Remove rules with the given condition
          #       l.delete_if do |r|
          #         r.matches_storage_class.include? "NEARLINE"
          #       end
          #       # Update rules
          #       l.each do |r|
          #         r.age = 90 if r.action == "Delete"
          #       end
          #       # Add a rule
          #       l.add_set_storage_class_rule "COLDLINE", age: 10
          #     end
          #   end
          #
          class Rule
            attr_accessor :action
            attr_accessor :storage_class
            attr_accessor :age
            attr_accessor :created_before
            attr_accessor :custom_time_before
            attr_accessor :days_since_custom_time
            attr_accessor :days_since_noncurrent_time
            attr_accessor :is_live
            attr_accessor :matches_storage_class
            attr_accessor :noncurrent_time_before
            attr_accessor :num_newer_versions
            attr_accessor :matches_prefix
            attr_accessor :matches_suffix

            # @private
            def initialize action,
                           storage_class: nil,
                           age: nil,
                           created_before: nil,
                           custom_time_before: nil,
                           days_since_custom_time: nil,
                           days_since_noncurrent_time: nil,
                           is_live: nil,
                           matches_storage_class: nil,
                           noncurrent_time_before: nil,
                           num_newer_versions: nil,
                           matches_prefix: nil,
                           matches_suffix: nil
              @action = action
              @storage_class = storage_class
              @age = age
              @created_before = created_before
              @custom_time_before = custom_time_before
              @days_since_custom_time = days_since_custom_time
              @days_since_noncurrent_time = days_since_noncurrent_time
              @is_live = is_live
              @matches_storage_class = Array(matches_storage_class)
              @noncurrent_time_before = noncurrent_time_before
              @num_newer_versions = num_newer_versions
              @matches_prefix = Array(matches_prefix)
              @matches_suffix = Array(matches_suffix)
            end

            # @private
            # @return [Google::Apis::StorageV1::Bucket::Lifecycle]
            def to_gapi
              condition = condition_gapi(
                age,
                created_before,
                custom_time_before,
                days_since_custom_time,
                days_since_noncurrent_time,
                is_live,
                matches_storage_class,
                noncurrent_time_before,
                num_newer_versions,
                matches_prefix,
                matches_suffix
              )
              Google::Apis::StorageV1::Bucket::Lifecycle::Rule.new(
                action: action_gapi(action, storage_class),
                condition: condition
              )
            end

            # @private
            def action_gapi action, storage_class
              Google::Apis::StorageV1::Bucket::Lifecycle::Rule::Action.new(
                type: action,
                storage_class: storage_class
              )
            end

            # @private
            def condition_gapi age,
                               created_before,
                               custom_time_before,
                               days_since_custom_time,
                               days_since_noncurrent_time,
                               is_live,
                               matches_storage_class,
                               noncurrent_time_before,
                               num_newer_versions,
                               matches_prefix,
                               matches_suffix
              Google::Apis::StorageV1::Bucket::Lifecycle::Rule::Condition.new(
                age: age,
                created_before: created_before,
                custom_time_before: custom_time_before,
                days_since_custom_time: days_since_custom_time,
                days_since_noncurrent_time: days_since_noncurrent_time,
                is_live: is_live,
                matches_storage_class: Array(matches_storage_class),
                noncurrent_time_before: noncurrent_time_before,
                num_newer_versions: num_newer_versions,
                matches_prefix: Array(matches_prefix),
                matches_suffix: Array(matches_suffix)
              )
            end

            # @private
            # @param [Google::Apis::StorageV1::Bucket::Rule] gapi
            def self.from_gapi gapi
              action = gapi.action
              c = gapi.condition
              new(
                action.type,
                storage_class: action.storage_class,
                age: c.age,
                created_before: c.created_before,
                custom_time_before: c.custom_time_before,
                days_since_custom_time: c.days_since_custom_time,
                days_since_noncurrent_time: c.days_since_noncurrent_time,
                is_live: c.is_live,
                matches_storage_class: c.matches_storage_class,
                noncurrent_time_before: c.noncurrent_time_before,
                num_newer_versions: c.num_newer_versions,
                matches_prefix: c.matches_prefix,
                matches_suffix: c.matches_suffix
              )
            end

            # @private
            def freeze
              @matches_storage_class.freeze
              super
            end
          end
        end
      end
    end
  end
end
