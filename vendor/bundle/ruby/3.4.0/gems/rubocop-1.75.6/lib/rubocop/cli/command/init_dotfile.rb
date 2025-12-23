# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # Generate a .rubocop.yml file in the current directory.
      # @api private
      class InitDotfile < Base
        DOTFILE = ConfigFinder::DOTFILE

        self.command_name = :init

        def run
          path = File.expand_path(DOTFILE)

          if File.exist?(DOTFILE)
            warn Rainbow("#{DOTFILE} already exists at #{path}").red

            STATUS_ERROR
          else
            description = <<~DESC
              # The behavior of RuboCop can be controlled via the .rubocop.yml
              # configuration file. It makes it possible to enable/disable
              # certain cops (checks) and to alter their behavior if they accept
              # any parameters. The file can be placed either in your home
              # directory or in some project directory.
              #
              # RuboCop will start looking for the configuration file in the directory
              # where the inspected file is and continue its way up to the root directory.
              #
              # See https://docs.rubocop.org/rubocop/configuration
            DESC

            File.write(DOTFILE, description)

            puts "Writing new #{DOTFILE} to #{path}"

            STATUS_SUCCESS
          end
        end
      end
    end
  end
end
