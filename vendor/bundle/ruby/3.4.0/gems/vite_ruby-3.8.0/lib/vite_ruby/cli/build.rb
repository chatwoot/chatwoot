# frozen_string_literal: true

class ViteRuby::CLI::Build < ViteRuby::CLI::Vite
  DEFAULT_ENV = CURRENT_ENV || 'production'

  desc 'Bundle all entrypoints using Vite.'
  shared_options
  option(:ssr, desc: 'Build the SSR entrypoint instead', type: :boolean)
  option(:force, desc: 'Force the build even if assets have not changed', type: :boolean)
  option(:watch, desc: 'Start the Rollup watcher and rebuild on files changes', type: :boolean)
  option(:profile, desc: 'Gather performance metrics from the build ', type: :boolean)

  def call(**options)
    super { |args| ViteRuby.commands.build_from_task(*args) }
  end
end
