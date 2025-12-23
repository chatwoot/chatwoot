# frozen_string_literal: true

# Public: Encapsulates common tasks, available both programatically and from the
# CLI and Rake tasks.
class ViteRuby::Commands
  def initialize(vite_ruby)
    @vite_ruby = vite_ruby
  end

  # Public: Defaults to production, and exits if the build fails.
  def build_from_task(*args)
    with_node_env(ENV.fetch('NODE_ENV', 'production')) {
      ensure_log_goes_to_stdout {
        build(*args) || exit!
      }
    }
  end

  # Public: Builds all assets that are managed by Vite, from the entrypoints.
  def build(*args)
    builder.build(*args).tap { manifest.refresh }
  end

  # Public: Removes all build cache and previously compiled assets.
  def clobber
    dirs = [config.build_output_dir, config.ssr_output_dir, config.build_cache_dir, config.vite_cache_dir]
    dirs.each { |dir| dir.rmtree if dir.exist? }
    $stdout.puts "Removed vite cache and output dirs:\n\t#{ dirs.join("\n\t") }"
  end

  # Internal: Installs the binstub for the CLI in the appropriate path.
  def install_binstubs
    `bundle binstub vite_ruby --path #{ config.root.join('bin') }`
    `bundle config --delete bin`
  end

  # Internal: Checks if the npm version is 6 or lower.
  def legacy_npm_version?
    `npm --version`.to_i < 7 rescue false
  end

  # Internal: Checks if the yarn version is 1.x.
  def legacy_yarn_version?
    `yarn --version`.to_i < 2 rescue false
  end

  # Internal: Verifies if ViteRuby is properly installed.
  def verify_install
    unless File.exist?(config.root.join('bin/vite'))
      warn <<~WARN

        vite binstub not found.
        Have you run `bundle binstub vite_ruby`?
        Make sure the bin directory and bin/vite are not included in .gitignore
      WARN
    end

    config_path = config.root.join(config.config_path)
    unless config_path.exist?
      warn <<~WARN

        Configuration #{ config_path } file for vite-plugin-ruby not found.
        Make sure `bundle exec vite install` has run successfully before running dependent tasks.
      WARN
      exit!
    end
  end

  # Internal: Prints information about ViteRuby's environment.
  def print_info
    config.within_root do
      $stdout.puts "bin/vite present?: #{ File.exist? 'bin/vite' }"

      $stdout.puts "vite_ruby: #{ ViteRuby::VERSION }"
      ViteRuby.framework_libraries.each do |framework, library|
        $stdout.puts "#{ library.name }: #{ library.version }"
        $stdout.puts "#{ framework }: #{ Gem.loaded_specs[framework]&.version }"
      end

      $stdout.puts "ruby: #{ `ruby --version` }"
      $stdout.puts "node: #{ `node --version` }"

      pkg = config.package_manager
      $stdout.puts "#{ pkg }: #{ `#{ pkg } --version` rescue nil }"

      $stdout.puts "\n"
      packages = `npm ls vite vite-plugin-ruby`
      packages_msg = packages.include?('vite@') ? "installed packages:\n#{ packages }" : '❌ Check that vite and vite-plugin-ruby have been added as development dependencies and installed.'
      $stdout.puts packages_msg

      ViteRuby::CompatibilityCheck.verify_plugin_version(config.root)
    end
  end

private

  extend Forwardable

  def_delegators :@vite_ruby, :config, :builder, :manifest, :logger, :logger=

  def with_node_env(env)
    original = ENV['NODE_ENV']
    ENV['NODE_ENV'] = env
    yield
  ensure
    ENV['NODE_ENV'] = original
  end

  def ensure_log_goes_to_stdout
    old_logger, original_sync = logger, $stdout.sync

    $stdout.sync = true
    self.logger = Logger.new($stdout, formatter: proc { |_, _, progname, msg| progname == 'vite' ? msg : "#{ msg }\n" })
    yield
  ensure
    self.logger, $stdout.sync = old_logger, original_sync
  end
end
