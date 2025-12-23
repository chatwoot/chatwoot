# frozen_string_literal: true

require 'etc'

require_relative 'identity'

module Datadog
  module Core
    module Environment
      # For gathering information about the platform
      module Platform
        module_function

        # @return [String] ISA of host; `uname -m`
        def architecture
          (Identity.lang_version >= '2.2') ? Etc.uname[:machine] : Gem::Platform.local.cpu
        end

        # @return [String] name of host; `uname -n`
        def hostname
          (Identity.lang_version >= '2.2') ? Etc.uname[:nodename] : nil
        end

        # System name, normally `Linux` or `Darwin` (but 'Mac OS X' on JRuby);
        # @return [String] name of kernel; `uname -s`.
        def kernel_name
          (Identity.lang_version >= '2.2') ? Etc.uname[:sysname] : Gem::Platform.local.os.capitalize
        end

        # @return [String] kernel release; `uname -r`
        def kernel_release
          if Identity.lang_engine == 'jruby'
            Etc.uname[:version] # Java's `os.version` maps to `uname -r`
          elsif Identity.lang_version >= '2.2'
            Etc.uname[:release]
          end
        end

        # @return [String] kernel version; `uname -v`
        def kernel_version
          Etc.uname[:version] if Identity.lang_engine != 'jruby' && Identity.lang_version >= '2.2'
        end
      end
    end
  end
end
