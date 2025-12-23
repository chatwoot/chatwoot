# frozen_string_literal: true

class ViteRuby::CLI::Version < Dry::CLI::Command
  desc 'Print version'

  def call(**)
    ViteRuby.commands.print_info
  end
end
