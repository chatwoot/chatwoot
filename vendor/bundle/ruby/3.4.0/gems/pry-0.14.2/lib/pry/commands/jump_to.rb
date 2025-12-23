# frozen_string_literal: true

class Pry
  class Command
    class JumpTo < Pry::ClassCommand
      match 'jump-to'
      group 'Navigating Pry'
      description 'Jump to a binding further up the stack.'

      banner <<-'BANNER'
        Jump to a binding further up the stack, popping all bindings below.
      BANNER

      def process(break_level)
        break_level    = break_level.to_i
        nesting_level  = pry_instance.binding_stack.size - 1
        max_nest_level = nesting_level - 1

        case break_level
        when nesting_level
          output.puts "Already at nesting level #{nesting_level}"
        when 0..max_nest_level
          pry_instance.binding_stack = pry_instance.binding_stack[0..break_level]
        else
          output.puts "Invalid nest level. Must be between 0 and " \
            "#{max_nest_level}. Got #{break_level}."
        end
      end
    end

    Pry::Commands.add_command(Pry::Command::JumpTo)
  end
end
