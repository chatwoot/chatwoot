# frozen_string_literal: true

class ViteRuby::CLI::Dev < ViteRuby::CLI::Vite
  DEFAULT_ENV = CURRENT_ENV || 'development'

  desc 'Start the Vite development server.'
  shared_options
  option(:force, desc: 'Force Vite to re-bundle dependencies', type: :boolean)

  def call(**options)
    super { |args| ViteRuby.run(args, exec: true) }
  end
end
