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


require "google/cloud/errors"

module Google
  module Cloud
    module Storage
      ##
      # # FileVerificationError
      #
      # Raised when a File download fails the verification.
      class FileVerificationError < Google::Cloud::Error
        ##
        # The type of digest that failed verification,
        # :md5 or :crc32c.
        attr_accessor :type

        ##
        # The value of the digest on the google-cloud file.
        attr_accessor :gcloud_digest

        ##
        # The value of the digest on the downloaded file.
        attr_accessor :local_digest

        # @private
        def self.for_md5 gcloud_digest, local_digest
          new("The downloaded file failed MD5 verification.").tap do |e|
            e.type = :md5
            e.gcloud_digest = gcloud_digest
            e.local_digest = local_digest
          end
        end

        # @private
        def self.for_crc32c gcloud_digest, local_digest
          new("The downloaded file failed CRC32c verification.").tap do |e|
            e.type = :crc32c
            e.gcloud_digest = gcloud_digest
            e.local_digest = local_digest
          end
        end
      end

      ##
      # # SignedUrlUnavailable Error
      #
      # Raised by signed URL methods if the service account credentials
      # are missing. Service account credentials are acquired by following the
      # steps in [Service Account Authentication](
      # https://cloud.google.com/iam/docs/service-accounts).
      #
      # @see https://cloud.google.com/storage/docs/access-control/signed-urls Signed URLs
      #
      class SignedUrlUnavailable < Google::Cloud::Error
      end
    end
  end
end
