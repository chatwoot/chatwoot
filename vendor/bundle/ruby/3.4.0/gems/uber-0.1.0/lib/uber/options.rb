require "uber/callable"
require "uber/option"

module Uber
  class Options < Hash
    def initialize(options)
      @static = options

      options.each do |k,v|
        self[k] = Option[v, instance_exec: true]
      end
    end

    # Evaluates every element and returns a hash.  Accepts context and arbitrary arguments.
    def evaluate(context, *args)
      {}.tap do |evaluated|
        each do |k,v|
          evaluated[k] = v.(context, *args)
        end
      end
    end

    # Evaluates a single value.
    def eval(key, *args)
      self[key].(*args)
    end

  private

    # DEPRECATED! PLEASE USE UBER::OPTION.
    class Value # TODO: rename to Value.
      def initialize(value, options={})
        @value, @dynamic = value, options[:dynamic]

        @proc     = proc?
        @callable = callable?
        @method   = method?

        return if options.has_key?(:dynamic)

        @dynamic = @proc || @callable || @method
      end

      def call(context, *args)
        return @value unless dynamic?

        evaluate_for(context, *args)
      end
      alias_method :evaluate, :call

      def dynamic?
        @dynamic
      end

      def proc?
        @value.kind_of?(Proc)
      end

      def callable?
        @value.is_a?(Uber::Callable)
      end

      def method?
        @value.is_a?(Symbol)
      end

    private
      def evaluate_for(*args)
        return proc!(*args)     if @proc
        return callable!(*args) if @callable
        method!(*args)
         # TODO: change to context.instance_exec and deprecate first argument.
      end

      def method!(context, *args)
        context.send(@value, *args)
      end

      def proc!(context, *args)
        if context.nil?
          @value.call(*args)
        else
          context.instance_exec(*args, &@value)
        end
      end

      # Callable object is executed in its original context.
      def callable!(context, *args)
        @value.call(context, *args)
      end
    end
  end
end
