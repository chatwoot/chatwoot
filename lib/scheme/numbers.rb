module Scheme::Numbers
  module_function

  def exact?(number)
    return exact?(number.real) && exact?(number.imaginary) if number.is_a?(Complex)

    number.is_a?(Integer) || number.is_a?(Rational)
  end

  def normalize(number)
    number.is_a?(Rational) && number.denominator == 1 ? number.numerator : number
  end

  def parse(token, radix = 10)
    text = token.dup
    exactness = nil
    prefix_radix = nil
    while text.start_with?('#')
      prefix = text.slice!(0, 2).downcase
      if %w[#e #i].include?(prefix)
        return false if exactness

        exactness = prefix
      else
        return false if prefix_radix

        prefix_radix = { '#b' => 2, '#o' => 8, '#d' => 10, '#x' => 16 }[prefix]
        return false unless prefix_radix
      end
    end
    radix = prefix_radix || radix
    value = parse_real(text, radix, exactness)
    return false unless value

    normalize(value)
  rescue ArgumentError, ZeroDivisionError, FloatDomainError
    false
  end

  def parse_real(text, radix, exactness)
    if radix == 10 && %w[+inf.0 -inf.0 +nan.0 -nan.0].include?(text.downcase)
      return false if exactness == '#e'
      return text.start_with?('-') ? -Float::INFINITY : Float::INFINITY if text.downcase.include?('inf')

      return Float::NAN
    end
    digits = { 2 => '[01]', 8 => '[0-7]', 10 => '[0-9]', 16 => '[0-9a-fA-F]' }.fetch(radix)
    if text.match?(%r{\A[+-]?#{digits}+(?:/#{digits}+)?\z})
      numerator, denominator = text.split('/')
      value = denominator ? Rational(Integer(numerator, radix), Integer(denominator, radix)) : Integer(numerator, radix)
      return exactness == '#i' ? value.to_f : value
    end
    return false unless radix == 10 && text.match?(/\A[+-]?(?:\d+\.?\d*|\.\d+)(?:[eEsSfFdDlL][+-]?\d+)?\z/)

    decimal = text.tr('sSfFdDlL', 'eeeeeeee')
    exactness == '#e' ? Rational(decimal) : Float(decimal)
  end
end
