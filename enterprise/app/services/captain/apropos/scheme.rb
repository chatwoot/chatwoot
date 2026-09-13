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

  attr_reader :bindings

  def initialize(bindings: {})
    @bindings = bindings
    @functions = {}
    install_core
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
    expressions = Captain::Apropos::Parser.new(source).parse
    @steps = MAX_STEPS
    expressions.map { |expression| evaluate(expression, nil, 0) }.last
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
  end

  def invoke(function, arguments, depth = 0)
    return function.call(*arguments) if function.is_a?(Proc)
    raise Captain::Apropos::Error, 'Value is not a procedure' unless function.is_a?(Closure)

    loop do
      raise Captain::Apropos::Error, 'Wrong number of arguments' unless arguments.length == function.parameters.length

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
  end

  def lookup(name, locals)
    return locals[name] if locals&.key?(name)
    return bindings[name] if bindings.key?(name)
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
    Captain::Apropos::Codec.dump(value) unless locals
    (locals || bindings)[args.first] = value
    args.first.to_s
  end

  def install_core
    register('list') { |*values| values }
    register('hash') { |*pairs| build_hash(*pairs) }
    register('get') { |value, key| value.fetch(key.to_s) }
    register('keys', &:keys)
    register('car') { |values| values.fetch(0) }
    register('cdr') { |values| values.drop(1) }
    register('length', &:length)
    register('null?') { |value| value == [] }
    register('nil?', &:nil?)
    register('not') { |value| value == false }
    register('equal?') { |a, b| a == b }
    install_collections
    install_arithmetic
  end

  def build_hash(*pairs)
    raise Captain::Apropos::Error, 'hash expects key/value pairs' if pairs.size.odd?

    pairs.each_slice(2).to_h.transform_keys(&:to_s)
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
