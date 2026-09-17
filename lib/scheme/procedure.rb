module Scheme
  Syntax = Struct.new(:name)
  Task = Struct.new(:work)
  Continuation = Struct.new(:continuation, :winders, :runtime)
  Winder = Struct.new(:before, :after, :on_abort)
  Parameter = Struct.new(:value, :converter)
  Promise = Struct.new(:state)
  CaseClosure = Struct.new(:clauses)
  Record = Struct.new(:type, :fields)
  ErrorObject = Struct.new(:message, :irritants)

  class UncaughtError < Error
    attr_reader :object

    def initialize(object)
      @object = object
      super(object.is_a?(ErrorObject) ? object.message : "uncaught exception: #{Scheme.write(object)}")
    end
  end

  class Native
    attr_reader :name, :control, :min, :max

    def initialize(name, min:, max:, control: false, &implementation)
      @name = name
      @min = min
      @max = max
      @control = control
      @implementation = implementation
    end

    def call(arguments, *context)
      unless arguments.length >= @min && (@max.nil? || arguments.length <= @max)
        expected = @max == @min ? @min.to_s : "#{@min}..#{@max || 'many'}"
        raise Error, "#{name}: expected #{expected} arguments, received #{arguments.length}"
      end

      @implementation.call(*arguments, *context)
    rescue TypeError, ArgumentError, ZeroDivisionError, RangeError, FrozenError => e
      raise Error, "#{name}: #{e.message}"
    end
  end

  class Closure
    attr_reader :body, :environment

    def initialize(parameters, body, environment)
      @required = []
      while parameters.is_a?(Pair)
        @required << parameters.car
        parameters = parameters.cdr
      end
      @rest = parameters.equal?(EMPTY) ? nil : parameters
      names = [*@required, @rest].compact
      raise Error, 'lambda parameters must be distinct identifiers' unless names.all?(Symbol) && names.uniq.length == names.length
      raise Error, 'lambda requires a body' if body.empty?

      @body = body
      @environment = environment
    end

    def bind(arguments)
      raise Error, "lambda: wrong number of arguments, received #{arguments.length}" unless accepts?(arguments.length)

      scope = Environment.new(environment)
      @required.zip(arguments).each { |name, value| scope.define(name, value) }
      scope.define(@rest, Scheme.list(arguments.drop(@required.length))) if @rest
      scope
    end

    def accepts?(count)
      count >= @required.length && (@rest || count == @required.length)
    end

    def parameters
      Scheme.list(@required, @rest || EMPTY)
    end
  end
end
