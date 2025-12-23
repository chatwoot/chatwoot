# frozen_string_literal: true

class Pry
  class Command
    class Cat < Pry::ClassCommand
      match 'cat'
      group 'Input and Output'
      description "Show code from a file, Pry's input buffer, or the last exception."

      banner <<-'BANNER'
        Usage: cat FILE
               cat --ex [STACK_INDEX]
               cat --in [INPUT_INDEX_OR_RANGE]

        `cat` is capable of showing part or all of a source file, the context of the
        last exception, or an expression from Pry's input history.

        `cat --ex` defaults to showing the lines surrounding the location of the last
        exception. Invoking it more than once travels up the exception's backtrace, and
        providing a number shows the context of the given index of the backtrace.
      BANNER

      def options(opt)
        opt.on :ex, "Show the context of the last exception",
               optional_argument: true, as: Integer
        opt.on :i, :in, "Show one or more entries from Pry's expression history",
               optional_argument: true, as: Range, default: -5..-1
        opt.on :s, :start, "Starting line (defaults to the first line)",
               optional_argument: true, as: Integer
        opt.on :e, :end, "Ending line (defaults to the last line)",
               optional_argument: true, as: Integer
        opt.on :l, :'line-numbers', "Show line numbers"
        opt.on :t, :type, "The file type for syntax highlighting " \
                          "(e.g., 'ruby' or 'python')",
               argument: true, as: Symbol
      end

      def process
        output =
          if opts.present?(:ex)
            ExceptionFormatter.new(
              pry_instance.last_exception, pry_instance, opts
            ).format
          elsif opts.present?(:in)
            InputExpressionFormatter.new(pry_instance.input_ring, opts).format
          else
            FileFormatter.new(args.first, pry_instance, opts).format
          end

        pry_instance.pager.page output
      end

      def complete(search)
        super | load_path_completions
      end

      def load_path_completions
        $LOAD_PATH.flat_map do |path|
          Dir[path + '/**/*'].map do |f|
            next if File.directory?(f)

            f.sub!(path + '/', '')
          end
        end
      end
    end

    Pry::Commands.add_command(Pry::Command::Cat)
  end
end
