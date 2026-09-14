class Captain::Apropos::Scheme
  include Captain::Apropos::BindingForms
  include Captain::Apropos::CollectionFunctions
  Closure = Struct.new(:parameters, :body, :locals, keyword_init: true)
  TailCall = Struct.new(:function, :arguments)
  MAX_STEPS = 100_000
  MAX_DEPTH = 128
  SPECIAL_FORMS = {
    quote: :quoted, define: :define_binding, lambda: :closure, if: :branch, begin: :sequence,
    let: :let_form, 'let*': :let_star, letrec: :let_recursive, and: :and_form, or: :or_form, cond: :cond_form
  }.freeze

  attr_reader :bindings, :library, :completed_bindings, :failed_binding, :feedback

  def initialize(bindings: {})
    @bindings = bindings
    @library = {}
    @functions = {}
    install_core
  end

  def library_function(expression)
    unless expression.is_a?(Array) && expression.first == :lambda
      raise Captain::Apropos::Error, 'Save a quoted lambda expression, not an evaluated closure or program'
    end

    closure(expression.drop(1), nil, 0, false)
  end

  def register(name)
    @functions[name.to_sym] = lambda do |*arguments|
      yield(*arguments)
    rescue Captain::Apropos::CallError
      raise
    rescue StandardError => e
      raise Captain::Apropos::CallError.new(name, e)
    end
  end

  def execute(source)
    @feedback = Captain::Apropos::ExecutionFeedback.new
    @completed_bindings = []
    @failed_binding = nil
    parser = Captain::Apropos::Parser.new(source)
    expressions = parser.parse
    feedback.stage = 'preflight'
    Captain::Apropos::ProgramPreflight.new(self).check(expressions)
    feedback.stage = 'execution'
    @steps = MAX_STEPS
    result = expressions.map { |expression| evaluate(expression, nil, 0) }.last
    feedback.stage = 'result serialization'
    result
  rescue StandardError
    feedback.location = parser.location if parser && feedback.stage == 'parsing'
    raise
  rescue SystemStackError
    raise Captain::Apropos::Error, 'Scheme call depth exceeded'
  end

  def evaluate(expression, locals, depth, tail: false)
    @steps -= 1
    raise Captain::Apropos::Error, 'Scheme evaluation budget exceeded' if @steps.negative? || depth > MAX_DEPTH
    return lookup(expression, locals) if expression.is_a?(Symbol)
    return expression unless expression.is_a?(Array)

    special = special_form(expression, locals, depth, tail)
    return special[1] if special[0]

    apply_expression(expression, locals, depth, tail)
  rescue StandardError => e
    feedback.capture(e, expression) if expression.is_a?(Array)
    raise
  end

  def invoke(function, arguments, depth = 0)
    return function.call(*arguments) if function.is_a?(Proc)
    raise Captain::Apropos::Error, 'Value is not a procedure' unless function.is_a?(Closure)

    loop do
      unless arguments.length == function.parameters.length
        raise Captain::Apropos::Error, "Expected #{function.parameters.length} arguments, received #{arguments.length}"
      end

      scope = Captain::Apropos::Scope.new(function.parameters.zip(arguments).to_h, function.locals)
      result = sequence(function.body, scope, depth, true)
      return result unless result.is_a?(TailCall)

      function = result.function
      arguments = result.arguments
    end
  end

  private

  def apply_expression(expression, locals, depth, tail)
    function = evaluate(expression.first, locals, depth + 1)
    arguments = expression.drop(1).map { |argument| evaluate(argument, locals, depth + 1) }
    tail && function.is_a?(Closure) ? TailCall.new(function, arguments) : invoke(function, arguments, depth + 1)
  rescue StandardError => e
    feedback.capture(e, expression, arguments)
    raise
  end

  def lookup(name, locals)
    return locals[name] if locals&.key?(name)
    return bindings[name] if bindings.key?(name)
    return library[name] if library.key?(name)
    return @functions[name] if @functions.key?(name)

    raise Captain::Apropos::Error, "Unknown binding: #{name}. Use apropos or describe."
  end

  def special_form(expression, locals, depth, tail)
    name, *args = expression
    handler = SPECIAL_FORMS[name]
    handler ? [true, send(handler, args, locals, depth, tail)] : [false, nil]
  end

  def quoted(args, _locals, _depth, _tail)
    raise Captain::Apropos::Error, 'quote expects one argument' unless args.size == 1

    args.first
  end

  def closure(args, locals, _depth, _tail)
    parameters, *body = args
    unless parameters.is_a?(Array) && parameters.all?(Symbol) && parameters.uniq == parameters && body.any?
      raise Captain::Apropos::Error, 'lambda requires unique symbol parameters and a body'
    end

    Closure.new(parameters: parameters, body: body, locals: locals)
  end

  def branch(args, locals, depth, tail)
    raise Captain::Apropos::Error, 'if expects condition, true branch, false branch' unless args.size == 3

    selected = evaluate(args[0], locals, depth + 1) == false ? args[2] : args[1]
    evaluate(selected, locals, depth + 1, tail: tail)
  end

  def sequence(args, locals, depth, tail)
    args[0...-1].each { |form| evaluate(form, locals, depth + 1) }
    args.empty? ? nil : evaluate(args.last, locals, depth + 1, tail: tail)
  end

  def define_binding(args, locals, depth, _tail)
    if args.first.is_a?(Array)
      name, *parameters = args.first
      args = [name, [:lambda, parameters, *args.drop(1)]]
    end
    raise Captain::Apropos::Error, 'define expects a symbol and value' unless args.size == 2 && args.first.is_a?(Symbol)

    value = evaluate(args.last, locals, depth + 1)
    store_binding(args.first, value, locals)
    args.first.to_s
  rescue StandardError
    @failed_binding ||= args.first.to_s unless locals
    raise
  end

  def store_binding(name, value, locals)
    return locals[name] = value if locals

    Captain::Apropos::Codec.dump(value)
    bindings[name] = value
    @completed_bindings |= [name.to_s]
  end

  def install_core
    Captain::Apropos::CoreFunctions.install(self)
    install_collections
    install_arithmetic
  end

  def install_collections
    register('append') { |*values| values.flatten(1) }
    register('map') do |function, values|
      validate_collection_call!(function, values)
      values.map { |value| invoke(function, [value]) }
    end
    register('filter') do |function, values|
      validate_collection_call!(function, values)
      values.reject { |value| invoke(function, [value]) == false }
    end
    register('fold') do |function, initial, values|
      validate_collection_call!(function, values)
      values.reduce(initial) { |memo, value| invoke(function, [memo, value]) }
    end
    install_list_functions
    install_ranking
  end

  def install_arithmetic
    %w[+ - * / = < > <= >=].each do |name|
      register(name) do |a, b|
        raise Captain::Apropos::Error, 'Arithmetic expects numbers' unless a.is_a?(Numeric) && b.is_a?(Numeric)

        a.public_send(name == '=' ? '==' : name, b)
      end
    end
  end
end
