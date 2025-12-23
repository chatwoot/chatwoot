# frozen_string_literal: true

module Bootsnap
  module CompileCache
    UNCOMPILABLE = BasicObject.new
    def UNCOMPILABLE.inspect
      "<Bootsnap::UNCOMPILABLE>"
    end

    Error = Class.new(StandardError)
    PermissionError = Class.new(Error)

    def self.setup(cache_dir:, iseq:, yaml:, json:, readonly: false)
      if iseq
        if supported?
          require_relative("compile_cache/iseq")
          Bootsnap::CompileCache::ISeq.install!(cache_dir)
        elsif $VERBOSE
          warn("[bootsnap/setup] bytecode caching is not supported on this implementation of Ruby")
        end
      end

      if yaml
        if supported?
          require_relative("compile_cache/yaml")
          Bootsnap::CompileCache::YAML.install!(cache_dir)
        elsif $VERBOSE
          warn("[bootsnap/setup] YAML parsing caching is not supported on this implementation of Ruby")
        end
      end

      if json
        if supported?
          require_relative("compile_cache/json")
          Bootsnap::CompileCache::JSON.install!(cache_dir)
        elsif $VERBOSE
          warn("[bootsnap/setup] JSON parsing caching is not supported on this implementation of Ruby")
        end
      end

      if supported? && defined?(Bootsnap::CompileCache::Native)
        Bootsnap::CompileCache::Native.readonly = readonly
      end
    end

    def self.permission_error(path)
      cpath = Bootsnap::CompileCache::ISeq.cache_dir
      raise(
        PermissionError,
        "bootsnap doesn't have permission to write cache entries in '#{cpath}' " \
        "(or, less likely, doesn't have permission to read '#{path}')",
      )
    end

    def self.supported?
      # only enable on 'ruby' (MRI), POSIX (darwin, linux, *bsd), Windows (RubyInstaller2) and >= 2.3.0
      RUBY_ENGINE == "ruby" && RUBY_PLATFORM.match?(/darwin|linux|bsd|mswin|mingw|cygwin/)
    end
  end
end
