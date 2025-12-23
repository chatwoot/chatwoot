# frozen_string_literal: true

require_relative "../command"

module Byebug
  #
  # Show byebug settings.
  #
  class ShowCommand < Command
    self.allow_in_control = true
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* show (?:\s+(?<setting>\w+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        show <setting> <value>

        #{short_description}

        You can change them with the "set" command.
      DESCRIPTION
    end

    def self.short_description
      "Shows byebug settings"
    end

    def self.help
      super + Setting.help_all
    end

    def execute
      key = @match[:setting]
      return puts(help) unless key

      setting = Setting.find(key)
      return errmsg(pr("show.errors.unknown_setting", key: key)) unless setting

      puts Setting.settings[setting.to_sym]
    end
  end
end
