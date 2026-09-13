# Lexical binding and short-circuit forms follow R7RS sections 4.2 and 5.3.
# https://standards.scheme.org/official/r7rs.pdf
module Captain::Apropos::BindingForms
  private

  def binding_pairs(value, duplicates: false)
    unless value.is_a?(Array) && value.all? { |pair| binding_pair?(pair) }
      raise Captain::Apropos::Error, 'Expected a list of (name expression) bindings'
    end

    names = value.map(&:first)
    raise Captain::Apropos::Error, 'Duplicate binding names' if !duplicates && names.uniq != names

    value
  end

  def binding_pair?(pair)
    pair.is_a?(Array) && pair.size == 2 && pair.first.is_a?(Symbol)
  end

  def let_form(args, locals, depth, tail)
    return named_let(args, locals, depth, tail) if args.first.is_a?(Symbol)

    pairs = binding_pairs(args.first)
    values = pairs.to_h.transform_values { |expression| evaluate(expression, locals, depth + 1) }
    sequence(args.drop(1), Captain::Apropos::Scope.new(values, locals), depth, tail)
  end

  def named_let(args, locals, depth, tail)
    name, definitions, *body = args
    pairs = binding_pairs(definitions)
    arguments = pairs.map { |_key, expression| evaluate(expression, locals, depth + 1) }
    scope = Captain::Apropos::Scope.new({}, locals)
    function = closure([pairs.map(&:first), *body], scope, depth, false)
    scope[name] = function
    tail ? self.class::TailCall.new(function, arguments) : invoke(function, arguments, depth + 1)
  end

  def let_star(args, locals, depth, tail)
    scope = Captain::Apropos::Scope.new({}, locals)
    binding_pairs(args.first, duplicates: true).each do |name, expression|
      scope = Captain::Apropos::Scope.new({ name => evaluate(expression, scope, depth + 1) }, scope)
    end
    sequence(args.drop(1), scope, depth, tail)
  end

  def let_recursive(args, locals, depth, tail)
    pairs = binding_pairs(args.first)
    placeholders = pairs.to_h.transform_values { Captain::Apropos::Scope::UNINITIALIZED }
    scope = Captain::Apropos::Scope.new(placeholders, locals)
    values = pairs.map { |name, expression| [name, evaluate(expression, scope, depth + 1)] }
    values.each { |name, value| scope[name] = value }
    sequence(args.drop(1), scope, depth, tail)
  end

  def and_form(args, locals, depth, tail)
    args[0...-1].each { |form| return false if evaluate(form, locals, depth + 1) == false }
    args.empty? || evaluate(args.last, locals, depth + 1, tail: tail)
  end

  def or_form(args, locals, depth, tail)
    args[0...-1].each do |form|
      value = evaluate(form, locals, depth + 1)
      return value unless value == false
    end
    args.empty? ? false : evaluate(args.last, locals, depth + 1, tail: tail)
  end

  def cond_form(args, locals, depth, tail)
    validate_clauses(args)
    args.each do |clause|
      value = clause.first == :else ? true : evaluate(clause.first, locals, depth + 1)
      next if value == false
      return value if clause.size == 1

      return sequence(clause.drop(1), locals, depth, tail)
    end
    nil
  end

  def validate_clauses(args)
    args.each_with_index do |clause, index|
      raise Captain::Apropos::Error, 'cond expects nonempty clauses' unless clause.is_a?(Array) && clause.any?
      raise Captain::Apropos::Error, 'else must be the last cond clause' if clause.first == :else && index != args.size - 1
      raise Captain::Apropos::Error, 'cond => clauses are not supported' if clause[1] == :'=>'
    end
  end
end
