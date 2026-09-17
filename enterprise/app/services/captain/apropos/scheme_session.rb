require 'scheme'

# Adapts Chatwoot's JSON-shaped tool values to Scheme data. Evaluation, syntax,
# standard procedures and tail calls belong exclusively to lib/scheme.
class Captain::Apropos::SchemeSession < Scheme::Runtime
  MAX_BYTES = 32_768
  MAX_STEPS = 100_000

  attr_reader :completed_bindings, :failed_binding, :feedback, :builtins, :library_environment

  def initialize
    super(max_steps: MAX_STEPS)
    @builtins = @environment
    @library_environment = ::Scheme::Environment.new(builtins)
    @environment = Captain::Apropos::Workspace.new(library_environment) do |value|
      Captain::Apropos::Codec.dump(value, roots: roots)
    end
    Captain::Apropos::CoreFunctions.install(self)
    Captain::Apropos::SchemeExtensions.install(self)
  end

  def roots
    { 'builtins' => builtins, 'library' => library_environment, 'globals' => environment }
  end

  def workspace = environment.bindings.transform_values(&:value)
  def library = library_environment.bindings.transform_values(&:value)
  def bind(name, value) = environment.define(name.to_sym, value)
  def install_library(name, value) = library_environment.define(name.to_sym, value)

  def standard_contracts
    builtins.bindings.to_h do |name, cell|
      procedure = cell.value
      contract = if procedure.is_a?(::Scheme::Native)
                   maximum = procedure.max || 'unbounded'
                   { signature: "(#{name} ...)", description: "Scheme procedure. Accepts #{procedure.min} to #{maximum} arguments." }
                 else
                   { signature: name.to_s, description: 'Scheme syntax form.' }
                 end
      [name.to_s, contract]
    end
  end

  def register(name, raw: false, &implementation)
    parameters = implementation.parameters
    minimum = implementation.arity.negative? ? -implementation.arity - 1 : implementation.arity
    maximum = parameters.any? { |kind, _| kind == :rest } ? nil : parameters.count { |kind, _| %i[req opt].include?(kind) }
    procedure = ::Scheme::Native.new(name, min: minimum, max: maximum) do |*arguments|
      result = yield(*(raw ? arguments : arguments.map { |value| Captain::Apropos::SchemeValues.to_ruby(value) }))
      raw ? result : Captain::Apropos::SchemeValues.from_ruby(result)
    rescue Captain::Apropos::CallError
      raise
    rescue StandardError => e
      raise Captain::Apropos::CallError.new(name, e)
    end
    builtins.define(name.to_sym, procedure)
  end

  def call(function, arguments)
    value = run(invoke(function, arguments.map { |argument| Captain::Apropos::SchemeValues.from_ruby(argument) }, ->(result) { result }))
    Captain::Apropos::SchemeValues.to_ruby(value)
  end

  def library_function(expression)
    forms = ::Scheme.to_a(expression)
    unless forms.first == :lambda && forms.length >= 3
      raise Captain::Apropos::Error, 'Save a quoted lambda expression, not an evaluated closure or program'
    end

    ::Scheme::Closure.new(forms[1], forms.drop(2), environment)
  end

  def execute(source)
    @feedback = Captain::Apropos::ExecutionFeedback.new
    @completed_bindings = []
    @failed_binding = nil
    raise Captain::Apropos::Error, 'Program must be a string of at most 32 KB' unless source.is_a?(String) && source.bytesize <= MAX_BYTES

    expressions = ::Scheme::Reader.new(source).read_all
    feedback.stage = 'preflight'
    Captain::Apropos::ProgramPreflight.new(self).check(expressions.map { |expression| Captain::Apropos::SchemeValues.expression(expression) })
    feedback.stage = 'execution'
    result = run(sequence(expressions, environment, ->(value) { value }))
    feedback.stage = 'result serialization'
    result
  rescue SystemStackError
    raise Captain::Apropos::Error, 'Scheme expression nesting exceeded the host limit'
  end

  def evaluate_expression(expression, scope, continuation)
    task = super
    defer do
      task.work.call
    rescue StandardError => e
      feedback&.capture(e, Captain::Apropos::SchemeValues.expression(expression))
      raise
    end
  end

  def invoke(procedure, arguments, continuation)
    task = super
    defer do
      task.work.call
    rescue StandardError => e
      name = procedure.is_a?(::Scheme::Native) ? procedure.name.to_sym : :lambda
      feedback&.capture(e, [name], arguments.map { |value| Captain::Apropos::SchemeValues.describe_value(value) })
      raise
    end
  end

  private

  def define_form(kind, arguments, scope, continuation)
    return super unless scope.equal?(environment)

    target = arguments.first
    names = if kind == :'define-values'
              values = []
              while target.is_a?(::Scheme::Pair)
                values << target.car
                target = target.cdr
              end
              values << target if target.is_a?(Symbol)
              values
            else
              [target.is_a?(::Scheme::Pair) ? target.car : target]
            end
    @failed_binding = names.first.to_s
    super(kind, arguments, scope, lambda { |value|
      @completed_bindings |= names.map(&:to_s)
      @failed_binding = nil
      continuation.call(value)
    })
  end
end
