require_relative 'standard/numeric'
require_relative 'standard/lists'
require_relative 'standard/sequences'

class Scheme::Standard
  include Scheme::StandardNumeric
  include Scheme::StandardLists
  include Scheme::StandardSequences

  def self.install(runtime)
    new(runtime).install
  end

  def initialize(runtime)
    @runtime = runtime
  end

  def install
    predicates
    numeric
    lists
    sequences
    control
  end

  private

  def register(name, min, max = min, &)
    @runtime.define(name, min: min, max: max, &)
  end

  def check(value, type, name = type.to_s)
    raise Scheme::Error, "expected #{name}, received #{Scheme.write(value)}" unless value.is_a?(type)

    value
  end

  def index(value, upper, inclusive: false)
    check(value, Integer, 'exact integer')
    unless value >= 0 && (inclusive ? value <= upper : value < upper)
      raise Scheme::Error,
            "index #{value} outside 0..#{inclusive ? upper : upper - 1}"
    end

    value
  end

  def length(value)
    check(value, Integer, 'exact nonnegative integer')
    raise Scheme::Error, 'expected nonnegative length' if value.negative?

    value
  end

  def mutable(value)
    raise Scheme::Error, 'cannot mutate an immutable literal' if value.frozen?

    value
  end

  def predicate(name, &)
    register(name, 1, &)
  end

  def predicates
    predicate('boolean?') { |value| value == true || value == false }
    predicate('symbol?') { |value| value.is_a?(Symbol) }
    predicate('string?') { |value| value.is_a?(String) }
    predicate('char?') { |value| value.is_a?(Scheme::Character) }
    predicate('vector?') { |value| value.instance_of?(Scheme::Vector) }
    predicate('bytevector?') { |value| value.is_a?(Scheme::Bytevector) }
    predicate('procedure?') do |value|
      [Scheme::Native, Scheme::Closure, Scheme::CaseClosure, Scheme::Continuation, Scheme::Parameter].any? { |type| value.is_a?(type) }
    end
    register('not', 1) { |value| value == false }
    register('eq?', 2) { |a, b| a.equal?(b) }
    register('eqv?', 2) { |a, b| Scheme.eqv?(a, b) }
    register('equal?', 2) { |a, b| Scheme.equal?(a, b) }
    register('boolean=?', 2, nil) do |*values|
      raise Scheme::Error, 'expected booleans' unless values.all? { |value| value == true || value == false }

      values.uniq.length == 1
    end
    register('symbol=?', 2, nil) { |*values| values.each { |value| check(value, Symbol) }.uniq.length == 1 }
    register('symbol->string', 1) { |value| check(value, Symbol).to_s.dup }
    register('string->symbol', 1) { |value| check(value, String).to_sym }
  end

  def control
    extended_control
    register('values', 0, nil) { |*values| values.length == 1 ? values.first : Scheme::MultipleValues.new(values) }
    @runtime.control('apply', min: 2, max: nil) do |procedure, *arguments, continuation|
      @runtime.invoke(procedure, arguments[0...-1] + Scheme.to_a(arguments.last), continuation)
    end
    @runtime.control('call-with-values', min: 2, max: 2) do |producer, consumer, continuation|
      @runtime.invoke(producer, [], lambda { |value|
        values = value.is_a?(Scheme::MultipleValues) ? value.items : [value]
        @runtime.invoke(consumer, values, continuation)
      })
    end
  end

  def extended_control
    @runtime.control('call-with-current-continuation', min: 1, max: 1) do |procedure, continuation|
      @runtime.invoke(procedure, [@runtime.capture(continuation)], continuation)
    end
    @runtime.environment.define(:'call/cc', @runtime.environment.get(:'call-with-current-continuation'))
    @runtime.control('dynamic-wind', min: 3, max: 3) { |before, thunk, after, k| @runtime.dynamic_wind(before, thunk, after, k) }
    @runtime.control('with-exception-handler', min: 2, max: 2) { |handler, thunk, k| @runtime.with_handler(handler, thunk, k) }
    @runtime.control('raise', min: 1, max: 1) { |object, k| @runtime.raise_object(object, k) }
    @runtime.control('raise-continuable', min: 1, max: 1) { |object, k| @runtime.raise_object(object, k, continuable: true) }
    @runtime.control('error', min: 1, max: nil) do |message, *irritants, k|
      @runtime.raise_object(Scheme::ErrorObject.new(check(message, String), irritants), k)
    end
    predicate('error-object?') { |value| value.is_a?(Scheme::ErrorObject) }
    register('error-object-message', 1) { |value| check(value, Scheme::ErrorObject).message }
    register('error-object-irritants', 1) { |value| Scheme.list(check(value, Scheme::ErrorObject).irritants) }
    predicate('promise?') { |value| value.is_a?(Scheme::Promise) }
    register('make-promise', 1) { |value| value.is_a?(Scheme::Promise) ? value : Scheme::Promise.new({ done: true, value: value }) }
    @runtime.control('force', min: 1, max: 1) { |promise, k| @runtime.force(promise, k) }
    @runtime.control('make-parameter', min: 1, max: 2) do |value, *optional, k|
      converter = optional.first
      if converter
        @runtime.invoke(converter, [value], ->(converted) { @runtime.deliver(k, Scheme::Parameter.new(@runtime.single(converted), converter)) })
      else
        @runtime.deliver(k, Scheme::Parameter.new(value, nil))
      end
    end
  end
end
