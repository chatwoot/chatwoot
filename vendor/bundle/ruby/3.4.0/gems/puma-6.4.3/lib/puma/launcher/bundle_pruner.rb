# frozen_string_literal: true

module Puma
  class Launcher

    # This class is used to pickup Gemfile changes during
    # application restarts.
    class BundlePruner

      def initialize(original_argv, extra_runtime_dependencies, log_writer)
        @original_argv = Array(original_argv)
        @extra_runtime_dependencies = Array(extra_runtime_dependencies)
        @log_writer = log_writer
      end

      def prune
        return if ENV['PUMA_BUNDLER_PRUNED']
        return unless defined?(Bundler)

        require_rubygems_min_version!

        unless puma_wild_path
          log "! Unable to prune Bundler environment, continuing"
          return
        end

        dirs = paths_to_require_after_prune

        log '* Pruning Bundler environment'
        home = ENV['GEM_HOME']
        bundle_gemfile = Bundler.original_env['BUNDLE_GEMFILE']
        bundle_app_config = Bundler.original_env['BUNDLE_APP_CONFIG']

        with_unbundled_env do
          ENV['GEM_HOME'] = home
          ENV['BUNDLE_GEMFILE'] = bundle_gemfile
          ENV['PUMA_BUNDLER_PRUNED'] = '1'
          ENV["BUNDLE_APP_CONFIG"] = bundle_app_config
          args = [Gem.ruby, puma_wild_path, '-I', dirs.join(':')] + @original_argv
          # Ruby 2.0+ defaults to true which breaks socket activation
          args += [{:close_others => false}]
          Kernel.exec(*args)
        end
      end

      private

      def require_rubygems_min_version!
        min_version = Gem::Version.new('2.2')

        return if min_version <= Gem::Version.new(Gem::VERSION)

        raise "prune_bundler is not supported on your version of RubyGems. " \
              "You must have RubyGems #{min_version}+ to use this feature."
      end

      def puma_wild_path
        puma_lib_dir = puma_require_paths.detect { |x| File.exist? File.join(x, '../bin/puma-wild') }
        File.expand_path(File.join(puma_lib_dir, '../bin/puma-wild'))
      end

      def with_unbundled_env
        bundler_ver = Gem::Version.new(Bundler::VERSION)
        if bundler_ver < Gem::Version.new('2.1.0')
          Bundler.with_clean_env { yield }
        else
          Bundler.with_unbundled_env { yield }
        end
      end

      def paths_to_require_after_prune
        puma_require_paths + extra_runtime_deps_paths
      end

      def extra_runtime_deps_paths
        t = @extra_runtime_dependencies.map do |dep_name|
          if (spec = spec_for_gem(dep_name))
            require_paths_for_gem(spec)
          else
            log "* Could not load extra dependency: #{dep_name}"
            nil
          end
        end
        t.flatten!; t.compact!; t
      end

      def puma_require_paths
        require_paths_for_gem(spec_for_gem('puma'))
      end

      def spec_for_gem(gem_name)
        Bundler.rubygems.loaded_specs(gem_name)
      end

      def require_paths_for_gem(gem_spec)
        gem_spec.full_require_paths
      end

      def log(str)
        @log_writer.log(str)
      end
    end
  end
end
