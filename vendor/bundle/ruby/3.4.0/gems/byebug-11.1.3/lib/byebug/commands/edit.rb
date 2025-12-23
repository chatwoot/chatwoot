# frozen_string_literal: true

require_relative "../command"

module Byebug
  #
  # Edit a file from byebug's prompt.
  #
  class EditCommand < Command
    self.allow_in_control = true
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* ed(?:it)? (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        edit[ file:lineno]

        #{short_description}

        With no argumnt, edits file containing most re line listed. Editing
        targets can also be specified to start editing at a specific line in a
        specific file
      DESCRIPTION
    end

    def self.short_description
      "Edits source files"
    end

    def execute
      file, line = location(@match[1])
      return edit_error("not_exist", file) unless File.exist?(file)
      return edit_error("not_readable", file) unless File.readable?(file)

      cmd = line ? "#{editor} +#{line} #{file}" : "#{editor} #{file}"

      Kernel.system(cmd)
    end

    private

    def location(matched)
      if matched.nil?
        file = frame.file
        return errmsg(pr("edit.errors.state")) unless file

        line = frame.line
      elsif (@pos_match = /([^:]+)[:]([0-9]+)/.match(matched))
        file, line = @pos_match.captures
      else
        file = matched
        line = nil
      end

      [File.expand_path(file), line]
    end

    def editor
      ENV["EDITOR"] || "vim"
    end

    def edit_error(type, file)
      errmsg(pr("edit.errors.#{type}", file: file))
    end
  end
end
