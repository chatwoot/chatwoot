# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/parse"

module Byebug
  #
  # Implements breakpoint deletion.
  #
  class DeleteCommand < Command
    include Helpers::ParseHelper

    self.allow_in_control = true
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* del(?:ete)? (?:\s+(.*))?$/x
    end

    def self.description
      <<-DESCRIPTION
        del[ete][ nnn...]

        #{short_description}

        Without and argument, deletes all breakpoints. With integer arguments,
        it deletes specific breakpoints.
      DESCRIPTION
    end

    def self.short_description
      "Deletes breakpoints"
    end

    def execute
      unless @match[1]
        Byebug.breakpoints.clear if confirm(pr("break.confirmations.delete_all"))

        return
      end

      @match[1].split(/ +/).each do |number|
        pos, err = get_int(number, "Delete", 1)

        return errmsg(err) unless pos

        if Breakpoint.remove(pos)
          puts(pr("break.messages.breakpoint_deleted", pos: pos))
        else
          errmsg(pr("break.errors.no_breakpoint_delete", pos: pos))
        end
      end
    end
  end
end
