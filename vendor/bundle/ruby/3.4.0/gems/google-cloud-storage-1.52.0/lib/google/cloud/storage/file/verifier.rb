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


require "pathname"
require "digest/md5"
require "digest/crc32c"
require "google/cloud/storage/errors"

module Google
  module Cloud
    module Storage
      class File
        ##
        # @private
        # Verifies downloaded files by creating an MD5 or CRC32c hash digest
        # and comparing the value to the one from the Storage API.
        module Verifier
          def self.verify_md5! gcloud_file, local_file
            gcloud_digest = gcloud_file.md5
            local_digest = md5_for local_file
            return if gcloud_digest == local_digest
            raise FileVerificationError.for_md5(gcloud_digest, local_digest)
          end

          def self.verify_crc32c! gcloud_file, local_file
            gcloud_digest = gcloud_file.crc32c
            local_digest = crc32c_for local_file
            return if gcloud_digest == local_digest
            raise FileVerificationError.for_crc32c(gcloud_digest, local_digest)
          end

          def self.verify_md5 gcloud_file, local_file
            gcloud_file.md5 == md5_for(local_file)
          end

          def self.verify_crc32c gcloud_file, local_file
            gcloud_file.crc32c == crc32c_for(local_file)
          end

          def self.md5_for local_file
            if local_file.respond_to? :to_path
              ::File.open Pathname(local_file).to_path, "rb" do |f|
                ::Digest::MD5.file(f).base64digest
              end
            else # StringIO
              local_file.rewind
              md5 = ::Digest::MD5.base64digest local_file.read
              local_file.rewind
              md5
            end
          end

          def self.crc32c_for local_file
            if local_file.respond_to? :to_path
              ::File.open Pathname(local_file).to_path, "rb" do |f|
                ::Digest::CRC32c.file(f).base64digest
              end
            else # StringIO
              local_file.rewind
              crc32c = ::Digest::CRC32c.base64digest local_file.read
              local_file.rewind
              crc32c
            end
          end
        end
      end
    end
  end
end
