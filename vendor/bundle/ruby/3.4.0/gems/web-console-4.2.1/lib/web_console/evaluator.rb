# frozen_string_literal: true

module WebConsole
  # Simple Ruby code evaluator.
  #
  # This class wraps a +Binding+ object and evaluates code inside of it. The
  # difference of a regular +Binding+ eval is that +Evaluator+ will always
  # return a string and will format exception output.
  class Evaluator
    # Cleanses exceptions raised inside #eval.
    cattr_reader :cleaner, default: begin
      cleaner = ActiveSupport::BacktraceCleaner.new
      cleaner.add_silencer { |line| line.start_with?(File.expand_path("..", __FILE__)) }
      cleaner
    end

    def initialize(binding = TOPLEVEL_BINDING)
      @binding = binding
    end

    def eval(input)
      # Binding#source_location is available since Ruby 2.6.
      if @binding.respond_to? :source_location
        "=> #{@binding.eval(input, *@binding.source_location).inspect}\n"
      else
        "=> #{@binding.eval(input).inspect}\n"
      end
    rescue Exception => exc
      format_exception(exc)
    end

    private

      def format_exception(exc)
        backtrace = cleaner.clean(Array(exc.backtrace) - caller)

        format = "#{exc.class.name}: #{exc}\n".dup
        format << backtrace.map { |trace| "\tfrom #{trace}\n" }.join
        format
      end
  end
end
