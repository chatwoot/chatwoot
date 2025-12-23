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

require "google/cloud/env/lazy_value"

module Google
  module Cloud
    class Env
      ##
      # Access to file system contents.
      #
      # This is a simple class that reads the contents of objects in the file
      # system, caching data so that subsequent accesses do not need to reread
      # the file system.
      #
      # You can also "mock" the file system by providing a hash of overrides.
      # If overrides are present, actual file system access is disabled; that
      # is, overrides are "all or nothing".
      #
      # This class does not provide any controls for data size. If you read a
      # large file, its contents will stay in memory for the lifetime of the
      # Ruby process.
      #
      class FileSystem
        ##
        # Create a file system access object with no overrides.
        #
        def initialize
          @overrides = nil
          @cache = LazyDict.new do |path, binary|
            if binary
              File.binread path
            else
              File.read path
            end
          rescue IOError, SystemCallError
            nil
          end
          # This mutex protects the overrides variable. Its setting (i.e.
          # whether nil or an overrides hash) will not change within a
          # synchronize block.
          @mutex = Thread::Mutex.new
        end

        ##
        # Read the given file from the file system and return its contents.
        #
        # @param path [String] The path to the file.
        # @param binary [boolean] Whether to read in binary mode. Defaults to
        #     false. This must be consistent across multiple requests for the
        #     same path; if it is not, an error will be raised.
        # @return [String] if the file exists.
        # @return [nil] if the file does not exist.
        #
        def read path, binary: false
          result = false
          @mutex.synchronize do
            result = @overrides[path] if @overrides
          end
          result = @cache.get(path, binary) if result == false
          if result && binary != (result.encoding == Encoding::ASCII_8BIT)
            raise IOError, "binary encoding flag mismatch"
          end
          result
        end

        ##
        # The overrides hash, or nil if overrides are not present.
        # The hash maps paths to contents of the file at that path.
        #
        # @return [Hash{String => String},nil]
        #
        attr_reader :overrides

        ##
        # Set the overrides hash. You can either provide a hash of file paths
        # to content, or nil to disable overrides. If overrides are present,
        # actual filesystem access is disabled; overrides are "all or nothing".
        #
        # @param new_overrides [Hash{String => String},nil]
        #
        def overrides= new_overrides
          @mutex.synchronize do
            @overrides = new_overrides
          end
        end

        ##
        # Run the given block with the overrides replaced with the given hash
        # (or nil to disable overrides in the block). The original overrides
        # setting is restored at the end of the block. This is used for
        # debugging/testing/mocking.
        #
        # @param temp_overrides [nil,Hash{String => String}]
        #
        def with_overrides temp_overrides
          old_overrides = @overrides
          begin
            @mutex.synchronize do
              @overrides = temp_overrides
            end
            yield
          ensure
            @mutex.synchronize do
              @overrides = old_overrides
            end
          end
        end
      end
    end
  end
end
