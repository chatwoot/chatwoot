# frozen_string_literal: true

require_relative "../command"

module Byebug
  #
  # Save current settings to use them in another debug session.
  #
  class SaveCommand < Command
    self.allow_in_control = true
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* sa(?:ve)? (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        save[ FILE]

        #{short_description}

        Byebug state is saved as a script file. This includes breakpoints,
        catchpoints, display expressions and some settings. If no filename is
        given, byebug will fabricate one.

        Use the "source" command in another debug session to restore the saved
        file.
      DESCRIPTION
    end

    def self.short_description
      "Saves current byebug session to a file"
    end

    def execute
      file = File.open(@match[1] || Setting[:savefile], "w")

      save_breakpoints(file)
      save_catchpoints(file)
      save_displays(file)
      save_settings(file)

      print pr("save.messages.done", path: file.path)
      file.close
    end

    private

    def save_breakpoints(file)
      Byebug.breakpoints.each do |b|
        file.puts "break #{b.source}:#{b.pos}#{" if #{b.expr}" if b.expr}"
      end
    end

    def save_catchpoints(file)
      Byebug.catchpoints.each_key do |c|
        file.puts "catch #{c}"
      end
    end

    def save_displays(file)
      Byebug.displays.each { |d| file.puts "display #{d[1]}" if d[0] }
    end

    def save_settings(file)
      %w[autoirb autolist basename].each do |setting|
        file.puts "set #{setting} #{Setting[setting.to_sym]}"
      end
    end
  end
end
