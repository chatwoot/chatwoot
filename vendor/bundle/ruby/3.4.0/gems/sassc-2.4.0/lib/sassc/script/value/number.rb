# frozen_string_literal: true

# A SassScript object representing a number.
# SassScript numbers can have decimal values,
# and can also have units.
# For example, `12`, `1px`, and `10.45em`
# are all valid values.
#
# Numbers can also have more complex units, such as `1px*em/in`.
# These cannot be inputted directly in Sass code at the moment.

class SassC::Script::Value::Number < SassC::Script::Value

  # The Ruby value of the number.
  #
  # @return [Numeric]
  attr_reader :value

  # A list of units in the numerator of the number.
  # For example, `1px*em/in*cm` would return `["px", "em"]`
  # @return [Array<String>]
  attr_reader :numerator_units

  # A list of units in the denominator of the number.
  # For example, `1px*em/in*cm` would return `["in", "cm"]`
  # @return [Array<String>]
  attr_reader :denominator_units

  # The original representation of this number.
  # For example, although the result of `1px/2px` is `0.5`,
  # the value of `#original` is `"1px/2px"`.
  #
  # This is only non-nil when the original value should be used as the CSS value,
  # as in `font: 1px/2px`.
  #
  # @return [Boolean, nil]
  attr_accessor :original

  def self.precision
    Thread.current[:sass_numeric_precision] || Thread.main[:sass_numeric_precision] || 10
  end

  # Sets the number of digits of precision
  # For example, if this is `3`,
  # `3.1415926` will be printed as `3.142`.
  # The numeric precision is stored as a thread local for thread safety reasons.
  # To set for all threads, be sure to set the precision on the main thread.
  def self.precision=(digits)
    Thread.current[:sass_numeric_precision] = digits.round
    Thread.current[:sass_numeric_precision_factor] = nil
    Thread.current[:sass_numeric_epsilon] = nil
  end

  # the precision factor used in numeric output
  # it is derived from the `precision` method.
  def self.precision_factor
    Thread.current[:sass_numeric_precision_factor] ||= 10.0**precision
  end

  # Used in checking equality of floating point numbers. Any
  # numbers within an `epsilon` of each other are considered functionally equal.
  # The value for epsilon is one tenth of the current numeric precision.
  def self.epsilon
    Thread.current[:sass_numeric_epsilon] ||= 1 / (precision_factor * 10)
  end

  # Used so we don't allocate two new arrays for each new number.
  NO_UNITS = []

  # @param value [Numeric] The value of the number
  # @param numerator_units [::String, Array<::String>] See \{#numerator\_units}
  # @param denominator_units [::String, Array<::String>] See \{#denominator\_units}
  def initialize(value, numerator_units = NO_UNITS, denominator_units = NO_UNITS)
    numerator_units = [numerator_units] if numerator_units.is_a?(::String)
    denominator_units = [denominator_units] if denominator_units.is_a?(::String)
    super(value)
    @numerator_units = numerator_units
    @denominator_units = denominator_units
    @options = nil
    normalize!
  end

  def hash
    [value, numerator_units, denominator_units].hash
  end

  # Hash-equality works differently than `==` equality for numbers.
  # Hash-equality must be transitive, so it just compares the exact value,
  # numerator units, and denominator units.
  def eql?(other)
    basically_equal?(value, other.value) && numerator_units == other.numerator_units &&
      denominator_units == other.denominator_units
  end

  # @return [String] The CSS representation of this number
  # @raise [Sass::SyntaxError] if this number has units that can't be used in CSS
  #   (e.g. `px*in`)
  def to_s(opts = {})
    return original if original
    raise Sass::SyntaxError.new("#{inspect} isn't a valid CSS value.") unless legal_units?
    inspect
  end

  # Returns a readable representation of this number.
  #
  # This representation is valid CSS (and valid SassScript)
  # as long as there is only one unit.
  #
  # @return [String] The representation
  def inspect(opts = {})
    return original if original

    value = self.class.round(self.value)
    str = value.to_s

    # Ruby will occasionally print in scientific notation if the number is
    # small enough. That's technically valid CSS, but it's not well-supported
    # and confusing.
    str = ("%0.#{self.class.precision}f" % value).gsub(/0*$/, '') if str.include?('e')

    # Sometimes numeric formatting will result in a decimal number with a trailing zero (x.0)
    if str =~ /(.*)\.0$/
      str = $1
    end

    # We omit a leading zero before the decimal point in compressed mode.
    if @options && options[:style] == :compressed
      str.sub!(/^(-)?0\./, '\1.')
    end

    unitless? ? str : "#{str}#{unit_str}"
  end
  alias_method :to_sass, :inspect

  # @return [Integer] The integer value of the number
  # @raise [Sass::SyntaxError] if the number isn't an integer
  def to_i
    super unless int?
    value.to_i
  end

  # @return [Boolean] Whether or not this number is an integer.
  def int?
    basically_equal?(value % 1, 0.0)
  end

  # @return [Boolean] Whether or not this number has no units.
  def unitless?
    @numerator_units.empty? && @denominator_units.empty?
  end

  # Checks whether the number has the numerator unit specified.
  #
  # @example
  #   number = Sass::Script::Value::Number.new(10, "px")
  #   number.is_unit?("px") => true
  #   number.is_unit?(nil) => false
  #
  # @param unit [::String, nil] The unit the number should have or nil if the number
  #   should be unitless.
  # @see Number#unitless? The unitless? method may be more readable.
  def is_unit?(unit)
    if unit
      denominator_units.size == 0 && numerator_units.size == 1 && numerator_units.first == unit
    else
      unitless?
    end
  end

  # @return [Boolean] Whether or not this number has units that can be represented in CSS
  #   (that is, zero or one \{#numerator\_units}).
  def legal_units?
    (@numerator_units.empty? || @numerator_units.size == 1) && @denominator_units.empty?
  end

  # Returns this number converted to other units.
  # The conversion takes into account the relationship between e.g. mm and cm,
  # as well as between e.g. in and cm.
  #
  # If this number has no units, it will simply return itself
  # with the given units.
  #
  # An incompatible coercion, e.g. between px and cm, will raise an error.
  #
  # @param num_units [Array<String>] The numerator units to coerce this number into.
  #   See {\#numerator\_units}
  # @param den_units [Array<String>] The denominator units to coerce this number into.
  #   See {\#denominator\_units}
  # @return [Number] The number with the new units
  # @raise [Sass::UnitConversionError] if the given units are incompatible with the number's
  #   current units
  def coerce(num_units, den_units)
    Number.new(if unitless?
                 value
               else
                 value * coercion_factor(@numerator_units, num_units) /
                   coercion_factor(@denominator_units, den_units)
               end, num_units, den_units)
  end

  # @param other [Number] A number to decide if it can be compared with this number.
  # @return [Boolean] Whether or not this number can be compared with the other.
  def comparable_to?(other)
    operate(other, :+)
    true
  rescue Sass::UnitConversionError
    false
  end

  # Returns a human readable representation of the units in this number.
  # For complex units this takes the form of:
  # numerator_unit1 * numerator_unit2 / denominator_unit1 * denominator_unit2
  # @return [String] a string that represents the units in this number
  def unit_str
    rv = @numerator_units.sort.join("*")
    if @denominator_units.any?
      rv << "/"
      rv << @denominator_units.sort.join("*")
    end
    rv
  end

  private

  # @private
  # @see Sass::Script::Number.basically_equal?
  def basically_equal?(num1, num2)
    self.class.basically_equal?(num1, num2)
  end

  # Checks whether two numbers are within an epsilon of each other.
  # @return [Boolean]
  def self.basically_equal?(num1, num2)
    (num1 - num2).abs < epsilon
  end

  # @private
  def self.round(num)
    if num.is_a?(Float) && (num.infinite? || num.nan?)
      num
    elsif basically_equal?(num % 1, 0.0)
      num.round
    else
      ((num * precision_factor).round / precision_factor).to_f
    end
  end

  OPERATIONS = [:+, :-, :<=, :<, :>, :>=, :%]

  def operate(other, operation)
    this = self
    if OPERATIONS.include?(operation)
      if unitless?
        this = this.coerce(other.numerator_units, other.denominator_units)
      else
        other = other.coerce(@numerator_units, @denominator_units)
      end
    end
    # avoid integer division
    value = :/ == operation ? this.value.to_f : this.value
    result = value.send(operation, other.value)

    if result.is_a?(Numeric)
      Number.new(result, *compute_units(this, other, operation))
    else # Boolean op
      Bool.new(result)
    end
  end

  def coercion_factor(from_units, to_units)
    # get a list of unmatched units
    from_units, to_units = sans_common_units(from_units, to_units)

    if from_units.size != to_units.size || !convertable?(from_units | to_units)
      raise Sass::UnitConversionError.new(
        "Incompatible units: '#{from_units.join('*')}' and '#{to_units.join('*')}'.")
    end

    from_units.zip(to_units).inject(1) {|m, p| m * conversion_factor(p[0], p[1])}
  end

  def compute_units(this, other, operation)
    case operation
    when :*
      [this.numerator_units + other.numerator_units,
       this.denominator_units + other.denominator_units]
    when :/
      [this.numerator_units + other.denominator_units,
       this.denominator_units + other.numerator_units]
    else
      [this.numerator_units, this.denominator_units]
    end
  end

  def normalize!
    return if unitless?
    @numerator_units, @denominator_units =
      sans_common_units(@numerator_units, @denominator_units)

    @denominator_units.each_with_index do |d, i|
      next unless convertable?(d) && (u = @numerator_units.find {|n| convertable?([n, d])})
      @value /= conversion_factor(d, u)
      @denominator_units.delete_at(i)
      @numerator_units.delete_at(@numerator_units.index(u))
    end
  end

  # This is the source data for all the unit logic. It's pre-processed to make
  # it efficient to figure out whether a set of units is mutually compatible
  # and what the conversion ratio is between two units.
  #
  # These come from http://www.w3.org/TR/2012/WD-css3-values-20120308/.
  relative_sizes = [
    {
      "in"   => Rational(1),
      "cm"   => Rational(1, 2.54),
      "pc"   => Rational(1, 6),
      "mm"   => Rational(1, 25.4),
      "q"    => Rational(1, 101.6),
      "pt"   => Rational(1, 72),
      "px"   => Rational(1, 96)
    },
    {
      "deg"  => Rational(1, 360),
      "grad" => Rational(1, 400),
      "rad"  => Rational(1, 2 * Math::PI),
      "turn" => Rational(1)
    },
    {
      "s"    => Rational(1),
      "ms"   => Rational(1, 1000)
    },
    {
      "Hz"   => Rational(1),
      "kHz"  => Rational(1000)
    },
    {
      "dpi"  => Rational(1),
      "dpcm" => Rational(254, 100),
      "dppx" => Rational(96)
    }
  ]

  # A hash from each known unit to the set of units that it's mutually
  # convertible with.
  MUTUALLY_CONVERTIBLE = {}
  relative_sizes.map do |values|
    set = values.keys.to_set
    values.keys.each {|name| MUTUALLY_CONVERTIBLE[name] = set}
  end

  # A two-dimensional hash from two units to the conversion ratio between
  # them. Multiply `X` by `CONVERSION_TABLE[X][Y]` to convert it to `Y`.
  CONVERSION_TABLE = {}
  relative_sizes.each do |values|
    values.each do |(name1, value1)|
      CONVERSION_TABLE[name1] ||= {}
      values.each do |(name2, value2)|
        value = value1 / value2
        CONVERSION_TABLE[name1][name2] = value.denominator == 1 ? value.to_i : value.to_f
      end
    end
  end

  def conversion_factor(from_unit, to_unit)
    CONVERSION_TABLE[from_unit][to_unit]
  end

  def convertable?(units)
    units = Array(units).to_set
    return true if units.empty?
    return false unless (mutually_convertible = MUTUALLY_CONVERTIBLE[units.first])
    units.subset?(mutually_convertible)
  end

  def sans_common_units(units1, units2)
    units2 = units2.dup
    # Can't just use -, because we want px*px to coerce properly to px*mm
    units1 = units1.map do |u|
      j = units2.index(u)
      next u unless j
      units2.delete_at(j)
      nil
    end
    units1.compact!
    return units1, units2
  end

end
