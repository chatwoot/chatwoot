# frozen_string_literal: true

# Copyright 2023 Google LLC
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
    class Env
      ##
      # Access to system environment variables.
      #
      # This is a hashlike object that controls access to environment variable
      # data. It supports temporarily changing the data source (i.e. swapping
      # ::ENV out for a different set of data) for mocking.
      #
      class Variables
        ##
        # Create an enviroment variables access object. This is initially
        # backed by the actual environment variables (i.e. ENV).
        #
        def initialize
          @backing_data = ::ENV
        end

        ##
        # Fetch the given environment variable from the backing data.
        #
        # @param key [String]
        # @return [String,nil]
        #
        def [] key
          @backing_data[key.to_s]
        end
        alias get []

        ##
        # The backing data is a hash or hash-like object that represents the
        # environment variable data. This can either be the actual environment
        # variables object (i.e. ENV) or a substitute hash used for mocking.
        #
        # @return [Hash{String=>String}]
        #
        attr_accessor :backing_data

        ##
        # Run the given block with the backing data replaced with the given
        # hash. The original backing data is restored afterward. This is used
        # for debugging/testing/mocking.
        #
        # @param temp_backing_data [Hash{String=>String}]
        #
        def with_backing_data temp_backing_data
          old_backing_data = @backing_data
          begin
            @backing_data = temp_backing_data
            yield
          ensure
            @backing_data = old_backing_data
          end
        end
      end
    end
  end
end
