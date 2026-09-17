class Scheme::Runtime
  include Scheme::Control

  SYNTAX = %i[import quote quasiquote if lambda begin define define-values set! and or cond case when unless
              let let* letrec letrec* let-values let*-values do delay delay-force case-lambda parameterize guard define-record-type].freeze
  DEFAULT_MAX_STEPS = 2_000_000

  attr_reader :environment

  def initialize(max_steps: DEFAULT_MAX_STEPS)
    @max_steps = max_steps
    @environment = Scheme::Environment.new
    @winders = []
    @handlers = []
    SYNTAX.each { |name| environment.define(name, Scheme::Syntax.new(name)) }
    Scheme::Standard.install(self)
  end

  def define(name, min:, max:, &)
    environment.define(name.to_sym, Scheme::Native.new(name, min: min, max: max, &))
  end

  def control(name, min:, max:, &)
    environment.define(name.to_sym, Scheme::Native.new(name, min: min, max: max, control: true, &))
  end

  def evaluate(source)
    expressions = Scheme::Reader.new(source).read_all
    task = sequence(expressions, environment, ->(value) { value })
    steps = 0
    while task.is_a?(Scheme::Task)
      steps += 1
      raise Scheme::LimitError, "evaluation exceeded #{@max_steps} steps" if steps > @max_steps

      begin
        task = task.work.call
      rescue Scheme::LimitError, Scheme::UncaughtError
        raise
      rescue Scheme::Error => e
        raise if @handlers.empty?

        task = raise_object(Scheme::ErrorObject.new(e.message, []), ->(value) { value })
      end
    end
    task
  ensure
    @winders = []
    @handlers = []
  end

  # Every evaluation and procedure transfer returns to this trampoline, including
  # apply and callbacks inside map. Tail calls never retain a Ruby stack frame.
  # R7RS-small sections 3.5 and 6.10: https://standards.scheme.org/official/r7rs.pdf
  def defer(&block)
    Scheme::Task.new(block)
  end

  def deliver(continuation, value)
    defer { continuation.call(value) }
  end

  def evaluate_expression(expression, scope, continuation)
    defer do
      case expression
      when Symbol then deliver(continuation, scope.get(expression))
      when Scheme::Pair
        arguments = Scheme.to_a(expression.cdr)
        evaluate_expression(expression.car, scope, lambda { |operator|
          operator = single(operator)
          if operator.is_a?(Scheme::Syntax)
            syntax(operator.name, arguments, scope, continuation)
          else
            evaluate_arguments(arguments, scope, [], ->(values) { invoke(operator, values, continuation) })
          end
        })
      else
        raise Scheme::Error, 'empty list is not an expression' if expression.equal?(Scheme::EMPTY)

        deliver(continuation, Scheme.literal(expression))
      end
    end
  end

  def invoke(procedure, arguments, continuation)
    defer do
      case procedure
      when Scheme::Native
        if procedure.control
          procedure.call(arguments, continuation)
        else
          deliver(continuation, procedure.call(arguments))
        end
      when Scheme::Closure
        body(procedure.body, procedure.bind(arguments), continuation)
      when Scheme::CaseClosure
        clause = procedure.clauses.find { |candidate| candidate.accepts?(arguments.length) }
        raise Scheme::Error, 'case-lambda: no clause accepts this number of arguments' unless clause

        invoke(clause, arguments, continuation)
      when Scheme::Continuation
        resume(procedure, arguments.length == 1 ? arguments.first : Scheme::MultipleValues.new(arguments))
      when Scheme::Parameter
        invoke_parameter(procedure, arguments, continuation)
      else
        raise Scheme::Error, "expected a procedure, received #{Scheme.write(procedure)}"
      end
    end
  end

  def sequence(expressions, scope, continuation)
    return deliver(continuation, Scheme::UNSPECIFIED) if expressions.empty?
    return evaluate_expression(expressions.first, scope, continuation) if expressions.length == 1

    evaluate_expression(expressions.first, scope, ->(_value) { sequence(expressions.drop(1), scope, continuation) })
  end

  def body(expressions, scope, continuation)
    # Internal definitions have letrec* scope. Reserve every location before any
    # initializer runs so an outer binding cannot leak into an uninitialized one.
    expressions = flatten_body(expressions, scope)
    expressions.take_while { |expression| definition?(expression, scope) }.each do |expression|
      kind, *parts = Scheme.to_a(expression)
      kind = scope.get(kind).name
      names = if kind == :'define-values'
                parameter_names(parts.first)
              else
                [parts.first.is_a?(Scheme::Pair) ? parts.first.car : parts.first]
              end
      names.each { |name| scope.define(name, Scheme::UNINITIALIZED) }
    end
    sequence(expressions, scope, continuation)
  end

  def single(value)
    return value unless value.is_a?(Scheme::MultipleValues)
    raise Scheme::Error, "expected one value, received #{value.items.length}" unless value.items.length == 1

    value.items.first
  end

  private

  def evaluate_arguments(expressions, scope, values, continuation)
    return deliver(continuation, values) if expressions.empty?

    evaluate_expression(expressions.first, scope, lambda { |value|
      evaluate_arguments(expressions.drop(1), scope, [*values, single(value)], continuation)
    })
  end

  def count!(name, arguments, min, max = min)
    return if arguments.length >= min && (max.nil? || arguments.length <= max)

    raise Scheme::Error, "#{name}: invalid number of forms (#{arguments.length})"
  end

  def syntax(name, arguments, scope, continuation)
    case name
    when :import
      # This embedded environment preloads its implemented procedures. Imports
      # are intentionally inert, including modifiers: no loading, aliasing, or
      # argument evaluation. This is a deliberate departure from R7RS libraries.
      deliver(continuation, Scheme::UNSPECIFIED)
    when :quote
      count!(name, arguments, 1)
      deliver(continuation, Scheme.literal(arguments.first))
    when :quasiquote
      count!(name, arguments, 1)
      quasiquote(arguments.first, scope, 1, continuation)
    when :if
      count!(name, arguments, 2, 3)
      evaluate_expression(arguments[0], scope, lambda { |test|
        chosen = single(test) == false ? arguments.fetch(2, Scheme::UNSPECIFIED) : arguments[1]
        evaluate_expression(chosen, scope, continuation)
      })
    when :lambda
      count!(name, arguments, 2, nil)
      deliver(continuation, Scheme::Closure.new(arguments.first, arguments.drop(1), scope))
    when :begin then sequence(arguments, scope, continuation)
    when :define, :'define-values' then define_form(name, arguments, scope, continuation)
    when :'set!'
      count!(name, arguments, 2)
      raise Scheme::Error, 'set! requires an identifier' unless arguments[0].is_a?(Symbol)

      evaluate_expression(arguments[1], scope, lambda { |value|
        scope.set(arguments[0], single(value))
        deliver(continuation, Scheme::UNSPECIFIED)
      })
    when :and, :or then boolean_form(name, arguments, scope, continuation)
    when :when, :unless
      count!(name, arguments, 1, nil)
      evaluate_expression(arguments.first, scope, lambda { |test|
        run = (single(test) != false) == (name == :when)
        run ? sequence(arguments.drop(1), scope, continuation) : deliver(continuation, Scheme::UNSPECIFIED)
      })
    when :cond then cond_form(arguments, scope, continuation)
    when :case
      count!(name, arguments, 1, nil)
      evaluate_expression(arguments.first, scope, ->(key) { case_form(single(key), arguments.drop(1), scope, continuation) })
    when :let, :'let*', :letrec, :'letrec*' then let_form(name, arguments, scope, continuation)
    when :'let-values', :'let*-values' then let_values(name, arguments, scope, continuation)
    when :do then do_form(arguments, scope, continuation)
    else control_syntax(name, arguments, scope, continuation)
    end
  end

  def define_form(kind, arguments, scope, continuation)
    count!(kind, arguments, 2, nil)
    target = arguments.first
    if kind == :define && target.is_a?(Scheme::Pair)
      scope.define(target.car, Scheme::Closure.new(target.cdr, arguments.drop(1), scope))
      return deliver(continuation, Scheme::UNSPECIFIED)
    end
    count!(kind, arguments, 2)
    evaluate_expression(arguments[1], scope, lambda { |value|
      if kind == :'define-values'
        bind_values(target, value, scope)
      else
        scope.define(target, single(value))
      end
      deliver(continuation, Scheme::UNSPECIFIED)
    })
  end

  def boolean_form(kind, expressions, scope, continuation)
    return deliver(continuation, kind == :and) if expressions.empty?
    return evaluate_expression(expressions.first, scope, continuation) if expressions.length == 1

    evaluate_expression(expressions.first, scope, lambda { |value|
      value = single(value)
      stop = kind == :and ? value == false : value != false
      stop ? deliver(continuation, value) : boolean_form(kind, expressions.drop(1), scope, continuation)
    })
  end

  def cond_form(clauses, scope, continuation)
    return deliver(continuation, Scheme::UNSPECIFIED) if clauses.empty?

    clause = Scheme.to_a(clauses.first)
    count!(:cond, clause, 1, nil)
    if clause.first == :else
      raise Scheme::Error, 'else must be the last cond clause' unless clauses.length == 1

      return sequence(clause.drop(1), scope, continuation)
    end
    evaluate_expression(clause.first, scope, lambda { |test|
      test = single(test)
      if test == false
        cond_form(clauses.drop(1), scope, continuation)
      elsif clause.length == 1
        deliver(continuation, test)
      elsif clause[1] == :'=>'
        count!(:cond, clause, 3)
        evaluate_expression(clause[2], scope, ->(proc) { invoke(single(proc), [test], continuation) })
      else
        sequence(clause.drop(1), scope, continuation)
      end
    })
  end

  def case_form(key, clauses, scope, continuation)
    clauses.each_with_index do |clause, index|
      items = Scheme.to_a(clause)
      count!(:case, items, 2, nil)
      raise Scheme::Error, 'else must be the last case clause' if items.first == :else && index != clauses.length - 1
      next unless items.first == :else || Scheme.to_a(items.first).any? { |datum| Scheme.eqv?(key, datum) }

      if items[1] == :'=>'
        count!(:case, items, 3)
        return evaluate_expression(items[2], scope, ->(proc) { invoke(single(proc), [key], continuation) })
      end
      return sequence(items.drop(1), scope, continuation)
    end
    deliver(continuation, Scheme::UNSPECIFIED)
  end

  def bindings(form, duplicates: false)
    pairs = Scheme.to_a(form).map do |pair|
      items = Scheme.to_a(pair)
      raise Scheme::Error, 'binding requires an identifier and initializer' unless items.length == 2 && items.first.is_a?(Symbol)

      items
    end
    raise Scheme::Error, 'duplicate binding' if !duplicates && pairs.map(&:first).uniq.length != pairs.length

    pairs
  end

  def let_form(kind, arguments, scope, continuation)
    count!(kind, arguments, 2, nil)
    if kind == :let && arguments.first.is_a?(Symbol)
      count!(kind, arguments, 3, nil)
      entries = bindings(arguments[1])
      recursive_scope = Scheme::Environment.new(scope)
      closure = Scheme::Closure.new(Scheme.list(entries.map(&:first)), arguments.drop(2), recursive_scope)
      recursive_scope.define(arguments.first, closure)
      return evaluate_arguments(entries.map(&:last), scope, [], ->(values) { invoke(closure, values, continuation) })
    end
    entries = bindings(arguments.first, duplicates: kind == :'let*')
    local = Scheme::Environment.new(scope)
    expressions = arguments.drop(1)
    case kind
    when :let
      evaluate_arguments(entries.map(&:last), scope, [], lambda { |values|
        entries.zip(values).each { |(name, _), value| local.define(name, value) }
        body(expressions, local, continuation)
      })
    when :letrec
      entries.each { |name, _| local.define(name, Scheme::UNINITIALIZED) }
      evaluate_arguments(entries.map(&:last), local, [], lambda { |values|
        entries.zip(values).each { |(name, _), value| local.set(name, value) }
        body(expressions, local, continuation)
      })
    else
      entries.each { |name, _| local.define(name, Scheme::UNINITIALIZED) } if kind == :'letrec*'
      sequential_bind(entries, local, kind == :'let*', ->(bound) { body(expressions, bound, continuation) })
    end
  end

  def sequential_bind(entries, scope, nested, continuation)
    return deliver(continuation, scope) if entries.empty?

    name, expression = entries.first
    evaluate_expression(expression, scope, lambda { |value|
      target = nested ? Scheme::Environment.new(scope) : scope
      target.define(name, single(value))
      sequential_bind(entries.drop(1), target, nested, continuation)
    })
  end

  def let_values(kind, arguments, scope, continuation)
    count!(kind, arguments, 2, nil)
    entries = Scheme.to_a(arguments.first).map do |entry|
      parts = Scheme.to_a(entry)
      count!(kind, parts, 2)
      parts
    end
    names = entries.flat_map { |formals, _| parameter_names(formals) }
    raise Scheme::Error, 'duplicate binding' if kind == :'let-values' && names.uniq.length != names.length

    values_bind(entries, scope, Scheme::Environment.new(scope), kind == :'let*-values', lambda { |local|
      body(arguments.drop(1), local, continuation)
    })
  end

  def values_bind(entries, scope, local, sequential, continuation)
    return deliver(continuation, local) if entries.empty?

    formals, expression = entries.first
    evaluate_expression(expression, sequential ? local : scope, lambda { |value|
      target = sequential ? Scheme::Environment.new(local) : local
      bind_values(formals, value, target)
      values_bind(entries.drop(1), scope, target, sequential, continuation)
    })
  end

  def bind_values(formals, value, scope)
    values = value.is_a?(Scheme::MultipleValues) ? value.items : [value]
    names = parameter_names(formals)
    cursor = formals
    index = 0
    while cursor.is_a?(Scheme::Pair)
      raise Scheme::Error, 'not enough values for binding' if index >= values.length

      scope.define(cursor.car, values[index])
      cursor = cursor.cdr
      index += 1
    end
    if cursor.is_a?(Symbol)
      scope.define(names.last, Scheme.list(values.drop(index)))
    elsif index != values.length
      raise Scheme::Error, 'too many values for binding'
    end
  end

  def parameter_names(formals)
    names = []
    while formals.is_a?(Scheme::Pair)
      names << formals.car
      formals = formals.cdr
    end
    names << formals unless formals.equal?(Scheme::EMPTY)
    raise Scheme::Error, 'expected distinct identifiers' unless names.all?(Symbol) && names.uniq.length == names.length

    names
  end

  def do_form(arguments, scope, continuation)
    count!(:do, arguments, 2, nil)
    entries = Scheme.to_a(arguments.first).map do |entry|
      parts = Scheme.to_a(entry)
      count!(:do, parts, 2, 3)
      parts
    end
    names = entries.map(&:first)
    raise Scheme::Error, 'do requires distinct identifiers' unless names.all?(Symbol) && names.uniq.length == names.length

    test, *results = Scheme.to_a(arguments[1])
    raise Scheme::Error, 'do requires a termination test' unless test

    iterate = nil
    iterate = lambda do |values|
      local = Scheme::Environment.new(scope)
      names.zip(values).each { |name, value| local.define(name, value) }
      evaluate_expression(test, local, lambda { |finished|
        if single(finished) == false
          sequence(arguments.drop(2), local, lambda { |_ignored|
            evaluate_arguments(entries.map { |entry| entry.fetch(2, entry.first) }, local, [], iterate)
          })
        else
          sequence(results, local, continuation)
        end
      })
    end
    evaluate_arguments(entries.map { |entry| entry[1] }, scope, [], iterate)
  end

  def quasiquote(datum, scope, depth, continuation)
    if datum.is_a?(Scheme::Vector)
      return quasiquote(Scheme.list(datum.items), scope, depth, ->(list) { deliver(continuation, Scheme::Vector.new(Scheme.to_a(list))) })
    end
    return deliver(continuation, datum) unless datum.is_a?(Scheme::Pair)

    if %i[unquote unquote-splicing quasiquote].include?(datum.car)
      parts = Scheme.to_a(datum.cdr)
      count!(datum.car, parts, 1)
      if depth == 1 && datum.car != :quasiquote
        raise Scheme::Error, 'unquote-splicing requires a list or vector element' if datum.car == :'unquote-splicing'

        return evaluate_expression(parts.first, scope, ->(value) { deliver(continuation, single(value)) })
      end
      nesting = depth + (datum.car == :quasiquote ? 1 : -1)
      return quasiquote(parts.first, scope, nesting, ->(value) { deliver(continuation, Scheme.list([datum.car, value])) })
    end
    head = datum.car
    if depth == 1 && head.is_a?(Scheme::Pair) && head.car == :'unquote-splicing'
      parts = Scheme.to_a(head.cdr)
      count!(:'unquote-splicing', parts, 1)
      return evaluate_expression(parts.first, scope, lambda { |value|
        items = Scheme.to_a(single(value))
        quasiquote(datum.cdr, scope, depth, ->(tail) { deliver(continuation, Scheme.list(items, tail)) })
      })
    end
    defer do
      quasiquote(datum.car, scope, depth, lambda { |car|
        quasiquote(datum.cdr, scope, depth, ->(cdr) { deliver(continuation, Scheme::Pair.new(car, cdr)) })
      })
    end
  end

  def definition?(expression, scope)
    return false unless expression.is_a?(Scheme::Pair) && expression.car.is_a?(Symbol)

    binding = scope.cell(expression.car)&.value
    binding.is_a?(Scheme::Syntax) && %i[define define-values].include?(binding.name)
  end

  def flatten_body(expressions, scope)
    expressions.flat_map do |expression|
      binding = expression.is_a?(Scheme::Pair) && expression.car.is_a?(Symbol) ? scope.cell(expression.car)&.value : nil
      if binding.is_a?(Scheme::Syntax) && binding.name == :begin
        flatten_body(Scheme.to_a(expression.cdr), scope)
      else
        [expression]
      end
    end
  end
end
