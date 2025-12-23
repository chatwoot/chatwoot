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

module Google
  module Cloud
    module Storage
      ##
      # # Notification
      #
      # Represents a Pub/Sub notification subscription for a Cloud Storage
      # bucket.
      #
      # See {Bucket#create_notification}, {Bucket#notifications}, and
      # {Bucket#notification}.
      #
      # @see https://cloud.google.com/storage/docs/pubsub-notifications Cloud
      #   Pub/Sub Notifications for Google Cloud
      #
      # @attr_reader [String] bucket The name of the {Bucket} to which this
      #   notification belongs.
      #
      # @example
      #   require "google/cloud/pubsub"
      #   require "google/cloud/storage"
      #
      #   pubsub = Google::Cloud::Pubsub.new
      #   storage = Google::Cloud::Storage.new
      #
      #   topic = pubsub.create_topic "my-topic"
      #   topic.policy do |p|
      #     p.add "roles/pubsub.publisher",
      #           "serviceAccount:#{storage.service_account_email}"
      #   end
      #
      #   bucket = storage.bucket "my-bucket"
      #
      #   notification = bucket.create_notification topic.name
      #
      class Notification
        ##
        # @private The Connection object.
        attr_accessor :service

        ##
        # @private The Google API Client object.
        attr_accessor :gapi

        ##
        # @private A boolean value or a project ID string to indicate the
        # project to be billed for operations.
        attr_accessor :user_project

        attr_reader :bucket

        ##
        # @private Creates a Notification object.
        def initialize
          @bucket = nil
          @service = nil
          @gapi = nil
          @user_project = nil
        end

        ##
        # The kind of item this is.
        # For notifications, this is always storage#notification.
        #
        # @return [String]
        #
        def kind
          @gapi.kind
        end

        ##
        # The ID of the notification.
        #
        # @return [String]
        #
        def id
          @gapi.id
        end

        ##
        # A URL that can be used to access the notification using the REST API.
        #
        # @return [String]
        #
        def api_url
          @gapi.self_link
        end

        ##
        # The custom attributes of this notification. An optional list of
        # additional attributes to attach to each Cloud Pub/Sub message
        # published for this notification subscription.
        #
        # @return [Hash(String => String)]
        #
        def custom_attrs
          @gapi.custom_attributes
        end

        ##
        # The event types of this notification. If present, messages will only
        # be sent for the listed event types. If empty, messages will be sent
        # for all event types.
        #
        # The following is a list of event types currently supported by Cloud
        # Storage:
        #
        # * `OBJECT_FINALIZE` - Sent when a new object (or a new generation of
        #   an existing object) is successfully created in the bucket. This
        #   includes copying or rewriting an existing object. A failed upload
        #   does not trigger this event.
        # * `OBJECT_METADATA_UPDATE` - Sent when the metadata of an existing
        #   object changes.
        # * `OBJECT_DELETE` - Sent when an object has been permanently deleted.
        #   This includes objects that are overwritten or are deleted as part of
        #   the bucket's lifecycle configuration. For buckets with object
        #   versioning enabled, this is not sent when an object is archived (see
        #   `OBJECT_ARCHIVE`), even if archival occurs via the {File#delete}
        #   method.
        # * `OBJECT_ARCHIVE` - Only sent when a bucket has enabled object
        #   versioning. This event indicates that the live version of an object
        #   has become an archived version, either because it was archived or
        #   because it was overwritten by the upload of an object of the same
        #   name.
        #
        # Important: Additional event types may be released later. Client code
        # should either safely ignore unrecognized event types, or else
        # explicitly specify in their notification configuration which event
        # types they are prepared to accept.
        #
        # @return [Array<String>]
        #
        def event_types
          @gapi.event_types
        end

        ##
        # The file name prefix of this notification. If present, only apply
        # this notification configuration to file names that begin with this
        # prefix.
        #
        # @return [String]
        #
        def prefix
          @gapi.object_name_prefix
        end

        ##
        # The desired content of the Pub/Sub message payload. Acceptable values
        # are:
        #
        # * `JSON_API_V1` - The payload will be a UTF-8 string containing the
        #   [resource
        #   representation](https://cloud.google.com/storage/docs/json_api/v1/objects#resource-representations)
        #   of the file's metadata.
        # * `NONE` - No payload is included with the notification.
        #
        # @return [String]
        #
        def payload
          @gapi.payload_format
        end

        ##
        # The Cloud Pub/Sub topic to which this subscription publishes.
        # Formatted as:
        # `//pubsub.googleapis.com/projects/{project-id}/topics/{my-topic}`
        #
        # @return [String]
        #
        def topic
          @gapi.topic
        end

        ##
        # Permanently deletes the notification.
        #
        # The API call to delete the notification may be retried under certain
        # conditions. See {Google::Cloud#storage} to control this behavior.
        #
        # @return [Boolean] Returns `true` if the notification was deleted.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #   notification = bucket.notification "1"
        #   notification.delete
        #
        def delete
          ensure_service!
          @service.delete_notification bucket, id, user_project: @user_project
          true
        end

        ##
        # @private New Notification from a
        # Google::Apis::StorageV1::Notification object.
        def self.from_gapi bucket_name, gapi, service, user_project: nil
          new.tap do |f|
            f.instance_variable_set :@bucket, bucket_name
            f.gapi = gapi
            f.service = service
            f.user_project = user_project
          end
        end

        protected

        ##
        # Raise an error unless an active service is available.
        def ensure_service!
          raise "Must have active connection" unless service
        end
      end
    end
  end
end
