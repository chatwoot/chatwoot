module Scheme::Control
  def capture(continuation)
    Scheme::Continuation.new(continuation, @winders, self)
  end

  def resume(captured, value)
    raise Scheme::Error, 'continuation belongs to another runtime' unless captured.runtime.equal?(self)

    wind_to(captured.winders, ->(_ignored) { deliver(captured.continuation, value) })
  end

  def dynamic_wind(before, thunk, after, continuation, on_abort: nil)
    winder = Scheme::Winder.new(before, after, on_abort)
    invoke(before, [], lambda { |_value|
      @winders = [*@winders, winder]
      invoke(thunk, [], lambda { |value|
        @winders = @winders[0...-1]
        invoke(after, [], ->(_ignored) { deliver(continuation, value) })
      })
    })
  end

  def with_handler(handler, thunk, continuation)
    outer = @handlers
    before = native_callback { @handlers = [*outer, handler] }
    after = native_callback { @handlers = outer }
    dynamic_wind(before, thunk, after, continuation)
  end

  def raise_object(object, continuation, continuable: false)
    raise Scheme::UncaughtError, object if @handlers.empty?

    current = @handlers
    @handlers = current[0...-1]
    invoke(current.last, [object], lambda { |value|
      if continuable
        @handlers = current
        deliver(continuation, value)
      else
        raise_object(Scheme::ErrorObject.new('exception handler returned from a non-continuable exception', [object]), continuation)
      end
    })
  end

  def force(promise, continuation)
    return deliver(continuation, promise) unless promise.is_a?(Scheme::Promise)
    return deliver(continuation, promise.state[:value]) if promise.state[:done]

    invoke(promise.state.fetch(:thunk), [], lambda { |value|
      unless promise.state[:done]
        if promise.state[:lazy]
          next_promise = single(value)
          raise Scheme::Error, 'delay-force expression must return a promise' unless next_promise.is_a?(Scheme::Promise)

          state = next_promise.state.dup
          next_promise.state = promise.state
          promise.state.replace(state)
        else
          promise.state.replace(done: true, value: value)
        end
      end
      force(promise, continuation)
    })
  end

  private

  def native_callback(&)
    Scheme::Native.new('dynamic context', min: 0, max: 0, &)
  end

  def wind_to(target, continuation)
    common = 0
    common += 1 while common < @winders.length && common < target.length && @winders[common].equal?(target[common])
    if @winders.length > common
      leaving = @winders.last
      @winders = @winders[0...-1]
      return invoke(leaving.after, [], ->(_ignored) { wind_to(target, continuation) })
    end
    if target.length > common
      entering = target[common]
      return invoke(entering.before, [], lambda { |_ignored|
        @winders = [*@winders, entering]
        wind_to(target, continuation)
      })
    end
    deliver(continuation, Scheme::UNSPECIFIED)
  end

  def control_syntax(name, arguments, scope, continuation)
    case name
    when :delay, :'delay-force'
      count!(name, arguments, 1)
      promise = Scheme::Promise.new({ done: false, thunk: Scheme::Closure.new(Scheme::EMPTY, arguments, scope), lazy: name == :'delay-force' })
      deliver(continuation, promise)
    when :'case-lambda'
      clauses = arguments.map do |clause|
        formals, *expressions = Scheme.to_a(clause)
        Scheme::Closure.new(formals, expressions, scope)
      end
      deliver(continuation, Scheme::CaseClosure.new(clauses))
    when :parameterize then parameterize(arguments, scope, continuation)
    when :guard then guard_form(arguments, scope, continuation)
    when :'define-record-type' then record_form(arguments, scope, continuation)
    end
  end

  def invoke_parameter(parameter, arguments, continuation)
    return deliver(continuation, parameter.value) if arguments.empty?
    raise Scheme::Error, 'parameter expects zero or one argument' unless arguments.length == 1

    converted = lambda do |value|
      parameter.value = single(value)
      deliver(continuation, Scheme::UNSPECIFIED)
    end
    parameter.converter ? invoke(parameter.converter, arguments, converted) : deliver(converted, arguments.first)
  end

  def parameterize(arguments, scope, continuation)
    count!(:parameterize, arguments, 2, nil)
    pairs = Scheme.to_a(arguments.first).map do |entry|
      parts = Scheme.to_a(entry)
      count!(:parameterize, parts, 2)
      parts
    end
    evaluate_arguments(pairs.flatten(1), scope, [], lambda { |values|
      parameter_bindings(values.each_slice(2).to_a, [], lambda { |settings|
        # Swapping cells, rather than resetting to initializer values, preserves
        # dynamic state when a continuation leaves and later reenters this extent.
        exchange_state = lambda do
          settings.each { |setting| setting[1], setting[0].value = setting[0].value, setting[1] }
          Scheme::UNSPECIFIED
        end
        exchange = native_callback(&exchange_state)
        dynamic_wind(exchange, Scheme::Closure.new(Scheme::EMPTY, arguments.drop(1), scope), exchange, continuation, on_abort: exchange_state)
      })
    })
  end

  def parameter_bindings(entries, settings, continuation)
    return deliver(continuation, settings) if entries.empty?

    parameter, value = entries.first
    raise Scheme::Error, 'parameterize requires parameter objects' unless parameter.is_a?(Scheme::Parameter)

    finish = lambda do |converted|
      parameter_bindings(entries.drop(1), [*settings, [parameter, single(converted)]], continuation)
    end
    parameter.converter ? invoke(parameter.converter, [value], finish) : deliver(finish, value)
  end

  def guard_form(arguments, scope, continuation)
    count!(:guard, arguments, 2, nil)
    variable, *clauses = Scheme.to_a(arguments.first)
    raise Scheme::Error, 'guard requires an identifier' unless variable.is_a?(Symbol)

    outside = capture(continuation)
    handler = Scheme::Native.new('guard handler', min: 1, max: 1, control: true) do |object, handler_return|
      # Reentering the dynamic extent reinstalls this guard's handler. Reraise
      # with the handler stack from the exception site, where it was already
      # removed, and preserve the original raise continuation for resumable errors.
      exception_handlers = @handlers
      at_raise = capture(lambda { |_value|
        @handlers = exception_handlers
        raise_object(object, handler_return, continuable: true)
      })
      wind_to(outside.winders, lambda { |_ignored|
        local = Scheme::Environment.new(scope)
        local.define(variable, object)
        fallback = Scheme::Native.new('guard propagation', min: 0, max: 0, control: true) { |k| resume(at_raise, k) }
        fallback_clause = Scheme.list([:else, Scheme.list([fallback])])
        selected = clauses.last.is_a?(Scheme::Pair) && clauses.last.car == :else ? clauses : [*clauses, fallback_clause]
        cond_form(selected, local, continuation)
      })
    end
    with_handler(handler, Scheme::Closure.new(Scheme::EMPTY, arguments.drop(1), scope), continuation)
  end

  def record_form(arguments, scope, continuation)
    count!(:'define-record-type', arguments, 3, nil)
    type_name, constructor, predicate, *fields = arguments
    constructor_name, *parameters = Scheme.to_a(constructor)
    declarations = fields.map do |field|
      parts = Scheme.to_a(field)
      count!(:'define-record-type', parts, 2, 3)
      raise Scheme::Error, 'record field names must be identifiers' unless parts.all?(Symbol)

      parts
    end
    names = declarations.map(&:first)
    raise Scheme::Error, 'duplicate record field' unless names.uniq.length == names.length
    raise Scheme::Error, 'invalid constructor fields' unless parameters.uniq.length == parameters.length && (parameters - names).empty?

    type = Object.new.freeze
    scope.define(type_name, type)
    scope.define(constructor_name, Scheme::Native.new(constructor_name, min: parameters.length, max: parameters.length) do |*values|
      # This interpreter runs without ActiveSupport, including in its standalone tests.
      data = names.to_h { |name| [name, Scheme::UNSPECIFIED] }.merge(parameters.zip(values).to_h) # rubocop:disable Rails/IndexWith
      Scheme::Record.new(type, data)
    end)
    scope.define(predicate, Scheme::Native.new(predicate, min: 1, max: 1) { |value| value.is_a?(Scheme::Record) && value.type.equal?(type) })
    declarations.each do |name, getter, setter|
      scope.define(getter, Scheme::Native.new(getter, min: 1, max: 1) do |record|
        raise Scheme::Error, "#{getter}: wrong record type" unless record.is_a?(Scheme::Record) && record.type.equal?(type)

        record.fields.fetch(name)
      end)
      next unless setter

      scope.define(setter, Scheme::Native.new(setter, min: 2, max: 2) do |record, value|
        raise Scheme::Error, "#{setter}: wrong record type" unless record.is_a?(Scheme::Record) && record.type.equal?(type)

        record.fields[name] = value
        Scheme::UNSPECIFIED
      end)
    end
    deliver(continuation, Scheme::UNSPECIFIED)
  end
end
