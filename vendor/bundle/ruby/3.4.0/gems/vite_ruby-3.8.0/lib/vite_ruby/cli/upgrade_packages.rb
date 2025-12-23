# frozen_string_literal: true

class ViteRuby::CLI::UpgradePackages < ViteRuby::CLI::Install
  desc 'Upgrades the npm packages to the recommended versions.'

  def call(**)
    say 'Upgrading npm packages'
    install_js_packages js_dependencies.join(' ')
  end
end
