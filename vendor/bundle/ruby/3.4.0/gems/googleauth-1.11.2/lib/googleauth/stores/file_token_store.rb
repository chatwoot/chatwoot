# Copyright 2014 Google, Inc.
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

require "yaml/store"
require "googleauth/token_store"

module Google
  module Auth
    module Stores
      # Implementation of user token storage backed by a local YAML file
      class FileTokenStore < Google::Auth::TokenStore
        # Create a new store with the supplied file.
        #
        # @param [String, File] file
        #  Path to storage file
        def initialize options = {}
          super()
          path = options[:file]
          @store = YAML::Store.new path
        end

        # (see Google::Auth::Stores::TokenStore#load)
        def load id
          @store.transaction { @store[id] }
        end

        # (see Google::Auth::Stores::TokenStore#store)
        def store id, token
          @store.transaction { @store[id] = token }
        end

        # (see Google::Auth::Stores::TokenStore#delete)
        def delete id
          @store.transaction { @store.delete id }
        end
      end
    end
  end
end
