module Scheme::StandardNumeric
  private

  def numeric
    predicate('number?') { |value| value.is_a?(Numeric) }
    predicate('complex?') { |value| value.is_a?(Numeric) }
    predicate('real?') { |value| value.is_a?(Numeric) && (!value.is_a?(Complex) || value.imaginary.zero?) }
    predicate('rational?') { |value| value.is_a?(Numeric) && !value.is_a?(Complex) && value.finite? }
    predicate('integer?') { |value| value.is_a?(Numeric) && !value.is_a?(Complex) && value.finite? && value == value.to_i }
    predicate('exact-integer?') { |value| value.is_a?(Integer) }
    predicate('exact?') { |value| Scheme::Numbers.exact?(check(value, Numeric)) }
    predicate('inexact?') { |value| !Scheme::Numbers.exact?(check(value, Numeric)) }
    predicate('zero?') { |value| check(value, Numeric).zero? }
    %w[positive negative].each do |name|
      predicate("#{name}?") { |value| real_number(value).public_send("#{name}?") }
    end
    %w[odd even].each { |name| predicate("#{name}?") { |value| integer_number(value).public_send("#{name}?") } }
    { '+' => [0, 0], '*' => [0, 1], '-' => [1, nil], '/' => [1, nil] }.each do |name, (minimum, identity)|
      register(name, minimum, nil) do |*values|
        values.each { |value| check(value, Numeric) }
        if values.empty?
          identity
        elsif values.length == 1 && %w[- /].include?(name)
          name == '-' ? -values.first : divide(1, values.first)
        else
          Scheme::Numbers.normalize(values.reduce { |a, b| name == '/' ? divide(a, b) : a.public_send(name, b) })
        end
      end
    end
    %w[= < > <= >=].each do |name|
      register(name, 2, nil) do |*values|
        values = values.map { |value| name == '=' ? check(value, Numeric) : real_number(value) }
        values.each_cons(2).all? { |a, b| a.public_send(name == '=' ? '==' : name, b) }
      end
    end
    %w[min max].each do |name|
      register(name, 1, nil) do |*values|
        values = values.map { |value| real_number(value) }
        result = values.public_send(name)
        values.any?(Float) ? result.to_f : result
      end
    end
    register('abs', 1) { |value| real_number(value).abs }
    register('square', 1) { |value| check(value, Numeric)**2 }
    register('expt', 2) { |base, exponent| Scheme::Numbers.normalize(check(base, Numeric)**check(exponent, Numeric)) }
    register('exact', 1) { |value| Scheme::Numbers.normalize(check(value, Numeric).to_r) }
    register('inexact', 1) { |value| check(value, Numeric).to_f }
    %w[floor ceiling truncate round].each do |name|
      register(name, 1) do |value|
        value = real_number(value)
        result = if name == 'round'
                   value.round(half: :even)
                 else
                   value.public_send(name == 'ceiling' ? 'ceil' : name)
                 end
        Scheme::Numbers.exact?(value) ? result : result.to_f
      end
    end
    %w[numerator denominator].each do |name|
      register(name, 1) do |value|
        value = real_number(value)
        result = value.to_r.public_send(name)
        Scheme::Numbers.exact?(value) ? result : result.to_f
      end
    end
    %w[gcd lcm].each do |name|
      register(name, 0, nil) do |*values|
        result = values.map { |value| integer_number(value) }.reduce(name == 'gcd' ? 0 : 1) { |a, b| a.public_send(name, b) }
        values.any?(Float) ? result.to_f : result
      end
    end
    numeric_division
    register('number->string', 1, 2) do |value, radix = 10|
      check(value, Numeric)
      raise Scheme::Error, 'radix must be 2, 8, 10, or 16' unless [2, 8, 10, 16].include?(radix)
      raise Scheme::Error, 'nondecimal formatting requires an exact integer' if radix != 10 && !value.is_a?(Integer)

      value.is_a?(Integer) ? value.to_s(radix) : Scheme.write(value)
    end
    register('string->number', 1, 2) do |value, radix = 10|
      raise Scheme::Error, 'radix must be 2, 8, 10, or 16' unless [2, 8, 10, 16].include?(radix)

      Scheme::Numbers.parse(check(value, String), radix)
    end
  end

  def divide(a, b)
    return Scheme::Numbers.normalize(a.to_r / b.to_r) if Scheme::Numbers.exact?(a) && Scheme::Numbers.exact?(b)

    a / b
  end

  def integer_number(value)
    check(value, Numeric)
    raise Scheme::Error, 'expected an integer' if value.is_a?(Complex) || !value.finite? || value != value.to_i

    value.to_i
  end

  def real_number(value)
    check(value, Numeric, 'a real number')
    return value unless value.is_a?(Complex)

    raise Scheme::Error, "expected a real number, received #{Scheme.write(value)}" unless value.imaginary.zero?

    value.real
  end

  def numeric_division
    { 'floor' => :floor, 'truncate' => :truncate }.each do |prefix, rounding|
      %w[/ -quotient -remainder].each do |suffix|
        register("#{prefix}#{suffix}", 2) do |a, b|
          quotient = Rational(integer_number(a), integer_number(b)).public_send(rounding)
          quotient = quotient.to_f if a.is_a?(Float) || b.is_a?(Float)
          remainder = a - (b * quotient)
          case suffix
          when '/' then Scheme::MultipleValues.new([quotient, remainder])
          when '-quotient' then quotient
          else remainder
          end
        end
      end
    end
    { 'quotient' => 'truncate-quotient', 'remainder' => 'truncate-remainder', 'modulo' => 'floor-remainder' }.each do |name, original|
      @runtime.environment.define(name.to_sym, @runtime.environment.get(original.to_sym))
    end
  end
end
