# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/eval"

module Byebug
  #
  # Implements exception catching.
  #
  # Enables the user to catch unhandled assertion when they happen.
  #
  class CatchCommand < Command
    include Helpers::EvalHelper

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* cat(?:ch)? (?:\s+(\S+))? (?:\s+(off))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        cat[ch][ (off|<exception>[ off])]

        #{short_description}

        catch                 -- lists catchpoints
        catch off             -- deletes all catchpoints
        catch <exception>     -- enables handling <exception>
        catch <exception> off -- disables handling <exception>
      DESCRIPTION
    end

    def self.short_description
      "Handles exception catchpoints"
    end

    def execute
      return info unless @match[1]

      return @match[1] == "off" ? clear : add(@match[1]) unless @match[2]

      return errmsg pr("catch.errors.off", off: cmd) unless @match[2] == "off"

      remove(@match[1])
    end

    private

    def remove(exception)
      return errmsg pr("catch.errors.not_found", exception: exception) unless Byebug.catchpoints.member?(exception)

      puts pr("catch.removed", exception: exception)
      Byebug.catchpoints.delete(exception)
    end

    def add(exception)
      errmsg pr("catch.errors.not_class", class: exception) if warning_eval(exception.is_a?(Class).to_s)

      puts pr("catch.added", exception: exception)
      Byebug.add_catchpoint(exception)
    end

    def clear
      Byebug.catchpoints.clear if confirm(pr("catch.confirmations.delete_all"))
    end

    def info
      if Byebug.catchpoints && !Byebug.catchpoints.empty?
        Byebug.catchpoints.each_key do |exception|
          puts("#{exception}: #{exception.is_a?(Class)}")
        end
      else
        puts "No exceptions set to be caught."
      end
    end
  end
end
