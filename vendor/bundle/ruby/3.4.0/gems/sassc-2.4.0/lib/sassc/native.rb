# frozen_string_literal: true

require "ffi"

module SassC
  module Native
    extend FFI::Library

    dl_ext = RbConfig::MAKEFILE_CONFIG['DLEXT']
    begin
      ffi_lib File.expand_path("libsass.#{dl_ext}", __dir__)
    rescue LoadError # Some non-rvm environments don't copy a shared object over to lib/sassc
      ffi_lib File.expand_path("libsass.#{dl_ext}", "#{__dir__}/../../ext")
    end

    require_relative "native/sass_value"

    typedef :pointer, :sass_options_ptr
    typedef :pointer, :sass_context_ptr
    typedef :pointer, :sass_file_context_ptr
    typedef :pointer, :sass_data_context_ptr

    typedef :pointer, :sass_c_function_list_ptr
    typedef :pointer, :sass_c_function_callback_ptr
    typedef :pointer, :sass_value_ptr

    typedef :pointer, :sass_import_list_ptr
    typedef :pointer, :sass_importer
    typedef :pointer, :sass_import_ptr

    callback :sass_c_function, [:pointer, :pointer], :pointer
    callback :sass_c_import_function, [:pointer, :pointer, :pointer], :pointer

    require_relative "native/sass_input_style"
    require_relative "native/sass_output_style"
    require_relative "native/string_list"

    # Remove the redundant "sass_" from the beginning of every method name
    def self.attach_function(*args)
      return super if args.size != 3

      if args[0] =~ /^sass_/
        args.unshift args[0].to_s.sub(/^sass_/, "")
      end

      super(*args)
    end

    # https://github.com/ffi/ffi/wiki/Examples#array-of-strings
    def self.return_string_array(ptr)
      ptr.null? ? [] : ptr.get_array_of_string(0).compact
    end

    def self.native_string(string)
      m = FFI::MemoryPointer.from_string(string)
      m.autorelease = false
      m
    end

    require_relative "native/native_context_api"
    require_relative "native/native_functions_api"
    require_relative "native/sass2scss_api"
  end
end
