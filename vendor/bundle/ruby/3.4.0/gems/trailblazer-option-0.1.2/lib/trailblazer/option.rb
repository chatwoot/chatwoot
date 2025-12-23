module Trailblazer
  class Option
    # A call implementation invoking `value.(*args, **keyword_arguments)` and plainly forwarding all arguments.
    # Override this for your own step strategy.
    # @private
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')
      def self.call!(value, *args, signal: :call, keyword_arguments: {}, **, &block)
        # NOTE: {**keyword_arguments} gets removed automatically if it's an empty hash.
        value.public_send(signal, *args, **keyword_arguments, &block)
      end
    else
      # Don't pass empty `keyword_arguments` because Ruby <= 2.6 passes an empty hash for `**{}`
      def self.call!(value, *args, signal: :call, keyword_arguments: nil, **, &block)
        return value.public_send(signal, *args, &block) unless keyword_arguments
        value.public_send(signal, *args, **keyword_arguments, &block)
      end
    end

    # Note that #evaluate_callable, #evaluate_proc and #evaluate_method drop most of the args.
    # If you need those, override this class.
    #
    # @private
    def self.evaluate_callable(value, *args, **options, &block)
      call!(value, *args, **options, &block)
    end

    # Pass given `value` as a block and evaluate it within `exec_context` binding.
    # @private
    def self.evaluate_proc(value, *args, signal: :instance_exec, exec_context: raise("No :exec_context given."), **options)
      call!(exec_context, *args, signal: signal, **options, &value)
    end

    # Make the exec_context's instance method a "lambda" and reuse #call!.
    # @private
    def self.evaluate_method(value, *args, exec_context: raise("No :exec_context given."), **options, &block)
      call!(exec_context.method(value), *args, **options, &block)
    end

    # Generic builder for a callable "option".
    # @param call_implementation [Class, Module] implements the process of calling the proc
    #   while passing arguments/options to it in a specific style (e.g. kw args, step interface).
    # @return [Proc] when called, this proc will evaluate its option (at run-time).
    def self.build(value)
      evaluate = case value
                 when Symbol then  method(:evaluate_method)
                 when Proc   then  method(:evaluate_proc)
                 else              method(:evaluate_callable)
                 end

      ->(*args, **options, &block) { evaluate.(value, *args, **options, &block) }
    end
  end

  def self.Option(value)
    Option.build(value)
  end
end
