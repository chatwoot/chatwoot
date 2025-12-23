# frozen_string_literal: true

module RuboCop
  # This class handles collecting the options for regenerating a TODO file.
  # @api private
  class ConfigRegeneration
    AUTO_GENERATED_FILE = RuboCop::CLI::Command::AutoGenerateConfig::AUTO_GENERATED_FILE
    COMMAND_REGEX = /(?<=`rubocop )(.*?)(?=`)/.freeze
    DEFAULT_OPTIONS = { auto_gen_config: true }.freeze

    # Get options from the comment in the TODO file, and parse them as options
    def options
      # If there's no existing TODO file, generate one
      return DEFAULT_OPTIONS unless todo_exists?

      match = generation_command.match(COMMAND_REGEX)
      return DEFAULT_OPTIONS unless match

      options = match[1].split
      Options.new.parse(options).first
    end

    private

    def todo_exists?
      File.exist?(AUTO_GENERATED_FILE) && !File.empty?(AUTO_GENERATED_FILE)
    end

    def generation_command
      File.foreach(AUTO_GENERATED_FILE).take(2).last
    end
  end
end
