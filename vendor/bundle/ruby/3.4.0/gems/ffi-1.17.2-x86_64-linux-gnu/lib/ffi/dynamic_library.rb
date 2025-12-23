#
# Copyright (C) 2008-2010 Wayne Meissner
#
# This file is part of ruby-ffi.
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the Ruby FFI project nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.#

module FFI
  class DynamicLibrary
    SEARCH_PATH = []

    # The following search paths are tried, if the library could not be loaded in the first attempt.
    # They are only executed on Macos in the following order:
    if FFI::Platform.mac?

      # 1. Try library paths possibly defined in LD_LIBRARY_PATH DYLD_LIBRARY_PATH first.
      # This is because dlopen doesn't respect LD_LIBRARY_PATH and DYLD_LIBRARY_PATH is deleted by SIP-protected binaries.
      # See here for details: https://github.com/ffi/ffi/issues/923#issuecomment-1872565313
      %w[LD_LIBRARY_PATH DYLD_LIBRARY_PATH].each do |custom_path|
        SEARCH_PATH.concat ENV.fetch(custom_path,"").split(File::PATH_SEPARATOR)
      end

      # 2. Then on macos/arm64 try /opt/homebrew/lib, since this is a typical standard directory.
      # FFI is often used together with homebrew, so that we hardcode the path for arm64 here.
      if FFI::Platform::ARCH == 'aarch64'
        SEARCH_PATH << '/opt/homebrew/lib'
      end

      # 3. Then try typical system directories starting with the /local/ directory first.
      #
      # /usr/local/lib is used by homebrow on x86_64.
      # /opt/local/lib is used by MacPorts and Fink.
      # /usr/lib is there, because it was always there.
      SEARCH_PATH.concat %w[/opt/local/lib /usr/local/lib /usr/lib]
    end

    # On Linux the library lookup paths are usually defined through /etc/ld.so.conf, which can be changed at will with root permissions.
    # Also LD_LIBRARY_PATH is respected by the dynamic loader, so that there's usually no need and no advantage to do a fallback handling.
    #
    # Windows has it's own library lookup logic, very different to what we do here.
    # See: https://github.com/oneclick/rubyinstaller2/wiki/For-gem-developers#user-content-dll-loading

    FFI.make_shareable(SEARCH_PATH)
    SEARCH_PATH_MESSAGE = "Searched in <system library path>#{ SEARCH_PATH.map{|a| ', ' + a}.join }".freeze

    def self.load_library(name, flags)
      if name == FFI::CURRENT_PROCESS
        FFI::DynamicLibrary.open(nil, RTLD_LAZY | RTLD_LOCAL)
      else
        flags ||= RTLD_LAZY | RTLD_LOCAL

        libnames = (name.is_a?(::Array) ? name : [name])
        libnames = libnames.map(&:to_s).map { |n| [n, FFI.map_library_name(n)].uniq }.flatten.compact
        errors = []

        libnames.each do |libname|
          lib = try_load(libname, flags, errors)
          return lib if lib

          unless libname.start_with?("/")
            SEARCH_PATH.each do |prefix|
              path = "#{prefix}/#{libname}"
              if File.exist?(path)
                lib = try_load(path, flags, errors)
                return lib if lib
              end
            end
          end
        end

        raise LoadError, [*errors, SEARCH_PATH_MESSAGE].join(".\n")
      end
    end
    private_class_method :load_library

    def self.try_load(libname, flags, errors)
      begin
        lib = FFI::DynamicLibrary.open(libname, flags)
        return lib if lib

      # LoadError for C ext & JRuby, RuntimeError for TruffleRuby
      rescue LoadError, RuntimeError => ex
        if ex.message =~ /(([^ \t()])+\.so([^ \t:()])*):([ \t])*(invalid ELF header|file too short|invalid file format)/
          if File.binread($1) =~ /(?:GROUP|INPUT) *\( *([^ \)]+)/
            return try_load($1, flags, errors)
          end
        end

        errors << ex
        nil
      end
    end
    private_class_method :try_load
  end
end
