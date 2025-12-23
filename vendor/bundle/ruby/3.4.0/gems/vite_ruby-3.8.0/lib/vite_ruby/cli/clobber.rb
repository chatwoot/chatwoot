# frozen_string_literal: true

class ViteRuby::CLI::Clobber < Dry::CLI::Command
  desc 'Clear the Vite cache, temp files, and builds'

  current_env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'

  option(:mode, default: current_env, values: %w[development production test], aliases: ['m'], desc: 'The mode to use')

  def call(mode:, **)
    ViteRuby.env['VITE_RUBY_MODE'] = mode
    ViteRuby.commands.clobber
  end
end
