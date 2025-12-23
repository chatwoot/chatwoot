# frozen_string_literal: true

require 'stringio'

class Pry
  module Testable
    class PryTester
      extend Pry::Forwardable
      attr_reader :pry, :out
      def_delegators :@pry, :eval_string, :eval_string=

      def initialize(target = TOPLEVEL_BINDING, options = {})
        @pry = Pry.new(options.merge(target: target))
        @history = options[:history]
        @pry.inject_sticky_locals!
        reset_output
      end

      def eval(*strs)
        reset_output
        result = nil

        strs.flatten.each do |str|
          # Check for space prefix. See #1369.
          str = "#{str.strip}\n" if str !~ /^\s\S/
          @history.push str if @history

          result =
            if @pry.process_command(str)
              last_command_result_or_output
            else
              # Check if this is a multiline paste.
              begin
                complete_expr = Pry::Code.complete_expression?(str)
              rescue SyntaxError => exception
                @pry.output.puts(
                  "SyntaxError: #{exception.message.sub(/.*syntax error, */m, '')}"
                )
              end
              @pry.evaluate_ruby(str) if complete_expr
            end
        end

        result
      end

      def push(*lines)
        Array(lines).flatten.each do |line|
          @pry.eval(line)
        end
      end

      def push_binding(context)
        @pry.push_binding context
      end

      def last_output
        @out.string if @out
      end

      def process_command(command_str)
        @pry.process_command(command_str) || raise("Not a valid command")
        last_command_result_or_output
      end

      def last_command_result
        result = Pry.current[:pry_cmd_result]
        result.retval if result
      end

      protected

      def last_command_result_or_output
        result = last_command_result
        if result != Pry::Command::VOID_VALUE
          result
        else
          last_output
        end
      end

      def reset_output
        @out = StringIO.new
        @pry.output = @out
      end
    end
  end
end
