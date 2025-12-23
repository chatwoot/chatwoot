# frozen_string_literal: true

$stdout.sync = true

require 'rake'

namespace :vite do
  task :binstubs do
    ViteRuby.commands.install_binstubs
  end

  desc 'Bundle frontend entrypoints using ViteRuby'
  task build: :'vite:verify_install' do
    ViteRuby.commands.build_from_task
  end

  desc 'Bundle a Node.js app from the SSR entrypoint using ViteRuby'
  task build_ssr: :'vite:verify_install' do
    ViteRuby.commands.build_from_task('--ssr')
  end

  desc 'Bundle entrypoints using Vite Ruby (SSR only if enabled)'
  task build_all: :'vite:verify_install' do
    ViteRuby.commands.build_from_task
    ViteRuby.commands.build_from_task('--ssr') if ViteRuby.config.ssr_build_enabled
  end

  desc 'Remove the build output directory for ViteRuby'
  task clobber: :'vite:verify_install' do
    ViteRuby.commands.clobber
  end

  desc 'Verify if ViteRuby is properly installed in the app'
  task :verify_install do
    ViteRuby.commands.verify_install
  end

  desc 'Ensure build dependencies like Vite are installed before bundling'
  task :install_dependencies do
    install_env_args = ENV['VITE_RUBY_SKIP_INSTALL_DEV_DEPENDENCIES'] == 'true' ? {} : { 'NODE_ENV' => 'development' }

    install_cmd = case (pkg = ViteRuby.config.package_manager)
    when 'npm' then 'npm ci'
    else "#{ pkg } install --frozen-lockfile"
    end

    system(install_env_args, install_cmd)
  end

  desc "Provide information on ViteRuby's environment"
  task :info do
    ViteRuby.commands.print_info
  end
end

unless ENV['VITE_RUBY_SKIP_ASSETS_PRECOMPILE_EXTENSION'] == 'true'
  if Rake::Task.task_defined?('assets:precompile')
    Rake::Task['assets:precompile'].enhance do |task|
      prefix = task.name.split(/#|assets:precompile/).first
      unless ENV['VITE_RUBY_SKIP_ASSETS_PRECOMPILE_INSTALL'] == 'true'
        Rake::Task["#{ prefix }vite:install_dependencies"].invoke
      end
      Rake::Task["#{ prefix }vite:build_all"].invoke
    end
  else
    desc 'Bundle Vite assets'
    if ENV['VITE_RUBY_SKIP_ASSETS_PRECOMPILE_INSTALL'] == 'true'
      Rake::Task.define_task('assets:precompile' => 'vite:build_all')
    else
      Rake::Task.define_task('assets:precompile' => ['vite:install_dependencies', 'vite:build_all'])
    end
  end

  if Rake::Task.task_defined?('assets:clobber')
    Rake::Task['assets:clobber'].enhance do
      Rake::Task['vite:clobber'].invoke
    end
  else
    desc 'Remove compiled assets'
    Rake::Task.define_task('assets:clobber' => 'vite:clobber')
  end
end

# Any prerequisite task that installs packages should also install build dependencies.
if ARGV.include?('assets:precompile')
  if ViteRuby.commands.legacy_npm_version?
    ENV['NPM_CONFIG_PRODUCTION'] = 'false'
  else
    ENV['NPM_CONFIG_INCLUDE'] = 'dev'
  end

  if ViteRuby.commands.legacy_yarn_version?
    ENV['YARN_PRODUCTION'] = 'false'
  end
end
