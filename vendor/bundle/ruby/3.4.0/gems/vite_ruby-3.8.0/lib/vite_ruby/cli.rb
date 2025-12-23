# frozen_string_literal: true

require 'dry/cli'

# Public: Command line interface that allows to install the library, and run
# simple commands.
class ViteRuby::CLI
  extend Dry::CLI::Registry

  register 'build', Build, aliases: ['b']
  register 'clobber', Clobber, aliases: %w[clean clear]
  register 'dev', Dev, aliases: %w[d serve]
  register 'install', Install
  register 'ssr', SSR
  register 'version', Version, aliases: ['v', '-v', '--version', 'info']
  register 'upgrade', Upgrade, aliases: ['update']
  register 'upgrade_packages', UpgradePackages, aliases: ['update_packages']

  # Internal: Allows framework-specific variants to extend the CLI.
  def self.require_framework_libraries(path = 'cli')
    ViteRuby.framework_libraries.each do |_framework, library|
      require [library.name.tr('-', '/').to_s, path].compact.join('/')
    end
  rescue LoadError
    require_framework_libraries 'installation' unless path == 'installation'
  end
end

# NOTE: This allows framework-specific variants to extend the CLI.
ViteRuby::CLI.require_framework_libraries('cli')
