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
      # Access to the SMBIOS information needed to determine if this Ruby
      # process is running on a Google compute platform.
      #
      # This information lives at a file system path on Linux, but in the
      # Registry on Windows.
      #
      # You can provide an override to "mock out" the behavior of this object.
      #
      class ComputeSMBIOS
        ##
        # Create an SMBIOS access object
        #
        def initialize
          @product_name_cache = LazyValue.new { load_product_name }
          @override_product_name = nil
        end

        ##
        # Read the product name. On a Google compute platform, this should
        # include the word "Google".
        #
        # This method may read the file system (on Linux) or registry (on
        # Windows) the first time it is called, but it will cache the result
        # for subsequent calls.
        #
        # @return [String] Product name, or the empty string if not found.
        #
        def product_name
          @override_product_name || @product_name_cache.get.first
        end

        ##
        # The source of the product name data. Will be one of the following:
        #
        # * `:linux` - The data comes from the Linux SMBIOS under /sys
        # * `:windows` - The data comes from the Windows Registry
        # * `:error` - The data could not be obtained
        # * `:override` - The data comes from an override
        #
        # This method may read the file system (on Linux) or registry (on
        # Windows) the first time it is called, but it will cache the result
        # for subsequent calls.
        #
        # @return [Symbol] The source
        #
        def product_name_source
          @override_product_name ? :override : @product_name_cache.get.last
        end

        ##
        # Determine whether the SMBIOS state suggests that we are running on a
        # Google compute platform.
        #
        # This method may read the file system (on Linux) or registry (on
        # Windows) the first time it is called, but it will cache the result
        # for subsequent calls.
        #
        # @return [true,false]
        #
        def google_compute?
          product_name.include? "Google"
        end

        ##
        # The current override value for the product name, either a string
        # value, or nil to disable mocking.
        #
        # @return [nil,String]
        #
        attr_accessor :override_product_name

        ##
        # Run the given block with the product name mock modified. This is
        # generally used for debugging/testing/mocking.
        #
        # @param override_name [nil,String]
        #
        def with_override_product_name override_name
          old_override = @override_product_name
          begin
            @override_product_name = override_name
            yield
          ensure
            @override_product_name = old_override
          end
        end

        private

        # @private The Windows registry key path
        WINDOWS_KEYPATH = "SYSTEM\\HardwareConfig\\Current"
        # @private The Windows registry key name
        WINDOWS_KEYNAME = "SystemProductName"
        # @private The Linux file path
        LINUX_FILEPATH = "/sys/class/dmi/id/product_name"

        private_constant :WINDOWS_KEYPATH, :WINDOWS_KEYNAME, :LINUX_FILEPATH

        def load_product_name
          require "win32/registry"
          Win32::Registry::HKEY_LOCAL_MACHINE.open WINDOWS_KEYPATH do |reg|
            return [reg[WINDOWS_KEYNAME].to_s, :windows]
          end
        rescue LoadError
          begin
            File.open LINUX_FILEPATH do |file|
              return [file.readline(chomp: true), :linux]
            end
          rescue IOError, SystemCallError
            ["", :error]
          end
        end
      end
    end
  end
end
