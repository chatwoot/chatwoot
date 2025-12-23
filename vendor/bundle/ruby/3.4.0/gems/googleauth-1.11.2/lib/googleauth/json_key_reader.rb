# Copyright 2015 Google, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    # JsonKeyReader contains the behaviour used to read private key and
    # client email fields from the service account
    module JsonKeyReader
      def read_json_key json_key_io
        json_key = MultiJson.load json_key_io.read
        raise "missing client_email" unless json_key.key? "client_email"
        raise "missing private_key" unless json_key.key? "private_key"
        [
          json_key["private_key"],
          json_key["client_email"],
          json_key["project_id"],
          json_key["quota_project_id"],
          json_key["universe_domain"]
        ]
      end
    end
  end
end
