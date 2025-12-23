# Copyright 2014 Google LLC
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
      ##
      # PostObject represents the URL, fields, and values needed to upload
      # objects via html forms.
      #
      # @see https://cloud.google.com/storage/docs/xml-api/post-object
      #
      # @attr_reader [String] url The URL the form must post to.
      # @attr_reader [Hash] fields The input fields that must be included in the
      #   form. Each key/value pair should be set as an input tag's name and
      #   value.
      #
      # @example Using Bucket#post_object (V2):
      #   require "google/cloud/storage"
      #
      #   storage = Google::Cloud::Storage.new
      #
      #   bucket = storage.bucket "my-todo-app"
      #   post = bucket.post_object "avatars/heidi/400x400.png"
      #
      #   post.url #=> "https://storage.googleapis.com"
      #   post.fields[:key] #=> "my-todo-app/avatars/heidi/400x400.png"
      #   post.fields[:GoogleAccessId] #=> "0123456789@gserviceaccount.com"
      #   post.fields[:signature] #=> "ABC...XYZ="
      #   post.fields[:policy] #=> "ABC...XYZ="
      #
      # @example Using Bucket#generate_signed_post_policy_v4 (V4):
      #   require "google/cloud/storage"
      #
      #   storage = Google::Cloud::Storage.new
      #
      #   bucket = storage.bucket "my-todo-app"
      #   conditions = [["starts-with","$acl","public"]]
      #   post = bucket.generate_signed_post_policy_v4 "avatars/heidi/400x400.png", expires: 10, conditions: conditions
      #
      #   post.url #=> "https://storage.googleapis.com/my-todo-app/"
      #   post.fields["key"] #=> "my-todo-app/avatars/heidi/400x400.png"
      #   post.fields["policy"] #=> "ABC...XYZ"
      #   post.fields["x-goog-algorithm"] #=> "GOOG4-RSA-SHA256"
      #   post.fields["x-goog-credential"] #=> "cred@pid.iam.gserviceaccount.com/20200123/auto/storage/goog4_request"
      #   post.fields["x-goog-date"] #=> "20200128T000000Z"
      #   post.fields["x-goog-signature"] #=> "4893a0e...cd82"
      #
      class PostObject
        attr_reader :url
        attr_reader :fields

        # @private
        def initialize url, fields
          @url = url
          @fields = fields
        end
      end
    end
  end
end
