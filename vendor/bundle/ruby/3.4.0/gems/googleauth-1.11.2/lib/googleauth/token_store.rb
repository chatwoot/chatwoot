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

module Google
  module Auth
    # Interface definition for token stores. It is not required that
    # implementations inherit from this class. It is provided for documentation
    # purposes to illustrate the API contract.
    class TokenStore
      class << self
        attr_accessor :default
      end

      # Load the token data from storage for the given ID.
      #
      # @param [String] id
      #  ID of token data to load.
      # @return [String]
      #  The loaded token data.
      def load _id
        raise NoMethodError, "load not implemented"
      end

      # Put the token data into storage for the given ID.
      #
      # @param [String] id
      #  ID of token data to store.
      # @param [String] token
      #  The token data to store.
      def store _id, _token
        raise NoMethodError, "store not implemented"
      end

      # Remove the token data from storage for the given ID.
      #
      # @param [String] id
      #  ID of the token data to delete
      def delete _id
        raise NoMethodError, "delete not implemented"
      end
    end
  end
end
