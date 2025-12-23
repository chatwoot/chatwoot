# Copyright 2013 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'json'

module Google
  class APIClient
    ##
    # Represents cached OAuth 2 tokens stored on local disk in a
    # JSON serialized file. Meant to resemble the serialized format
    # http://google-api-python-client.googlecode.com/hg/docs/epy/oauth2client.file.Storage-class.html
    #
    # @deprecated Use google-auth-library-ruby instead
    class FileStore

      attr_accessor :path

      ##
      # Initializes the FileStorage object.
      #
      # @param [String] path
      #    Path to the credentials file.
      def initialize(path)
        @path= path
      end

      ##
      # Attempt to read in credentials from the specified file.
      def load_credentials
        open(path, 'r') { |f| JSON.parse(f.read) }
      rescue
        nil
      end

      ##
      # Write the credentials to the specified file.
      #
      # @param [Hash] credentials_hash
      def write_credentials(credentials_hash)
        open(self.path, 'w+') do |f|
          f.write(credentials_hash.to_json)
        end
      end
    end
  end
end
