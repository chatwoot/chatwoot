# frozen_string_literal: true

class ViteRuby::CLI::Upgrade < ViteRuby::CLI::Install
  desc 'Updates Vite Ruby related gems and npm packages.'

  def call(**)
    upgrade_ruby_gems
    upgrade_npm_packages
  end

protected

  def upgrade_ruby_gems
    say 'Updating gems'

    libraries = ViteRuby.framework_libraries.map { |_f, library| library.name }

    run_with_capture("bundle update #{ libraries.join(' ') }")
  end

  # NOTE: Spawn a new process so that it uses the updated vite_ruby.
  def upgrade_npm_packages
    Kernel.exec('bundle exec vite upgrade_packages')
  end
end
