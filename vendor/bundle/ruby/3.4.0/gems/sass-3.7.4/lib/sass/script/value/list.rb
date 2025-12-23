module Sass::Script::Value
  # A SassScript object representing a CSS list.
  # This includes both comma-separated lists and space-separated lists.
  class List < Base
    # The Ruby array containing the contents of the list.
    #
    # @return [Array<Value>]
    attr_reader :value
    alias_method :to_a, :value

    # The operator separating the values of the list.
    # Either `:comma` or `:space`.
    #
    # @return [Symbol]
    attr_reader :separator

    # Whether the list is surrounded by square brackets.
    #
    # @return [Boolean]
    attr_reader :bracketed

    # Creates a new list.
    #
    # @param value [Array<Value>] See \{#value}
    # @param separator [Symbol] See \{#separator}
    # @param bracketed [Boolean] See \{#bracketed}
    def initialize(value, separator: nil, bracketed: false)
      super(value)
      @separator = separator
      @bracketed = bracketed
    end

    # @see Value#options=
    def options=(options)
      super
      value.each {|v| v.options = options}
    end

    # @see Value#eq
    def eq(other)
      Sass::Script::Value::Bool.new(
        other.is_a?(List) && value == other.value &&
        separator == other.separator && bracketed == other.bracketed)
    end

    def hash
      @hash ||= [value, separator, bracketed].hash
    end

    # @see Value#to_s
    def to_s(opts = {})
      if !bracketed && value.empty?
        raise Sass::SyntaxError.new("#{inspect} isn't a valid CSS value.")
      end

      members = value.
        reject {|e| e.is_a?(Null) || e.is_a?(List) && e.value.empty?}.
        map {|e| e.to_s(opts)}

      contents = members.join(sep_str)
      bracketed ? "[#{contents}]" : contents
    end

    # @see Value#to_sass
    def to_sass(opts = {})
      return bracketed ? "[]" : "()" if value.empty?
      members = value.map do |v|
        if element_needs_parens?(v)
          "(#{v.to_sass(opts)})"
        else
          v.to_sass(opts)
        end
      end

      if separator == :comma && members.length == 1
        return "#{bracketed ? '[' : '('}#{members.first},#{bracketed ? ']' : ')'}"
      end

      contents = members.join(sep_str(nil))
      bracketed ? "[#{contents}]" : contents
    end

    # @see Value#to_h
    def to_h
      return {} if value.empty?
      super
    end

    # @see Value#inspect
    def inspect
      (bracketed ? '[' : '(') +
        value.map {|e| e.inspect}.join(sep_str(nil)) +
        (bracketed ? ']' : ')')
    end

    # Asserts an index is within the list.
    #
    # @private
    #
    # @param list [Sass::Script::Value::List] The list for which the index should be checked.
    # @param n [Sass::Script::Value::Number] The index being checked.
    def self.assert_valid_index(list, n)
      if !n.int? || n.to_i == 0
        raise ArgumentError.new("List index #{n} must be a non-zero integer")
      elsif list.to_a.size == 0
        raise ArgumentError.new("List index is #{n} but list has no items")
      elsif n.to_i.abs > (size = list.to_a.size)
        raise ArgumentError.new(
          "List index is #{n} but list is only #{size} item#{'s' if size != 1} long")
      end
    end

    private

    def element_needs_parens?(element)
      if element.is_a?(List)
        return false if element.value.length < 2
        return false if element.bracketed
        precedence = Sass::Script::Parser.precedence_of(separator || :space)
        return Sass::Script::Parser.precedence_of(element.separator || :space) <= precedence
      end

      return false unless separator == :space
      return false unless element.is_a?(Sass::Script::Tree::UnaryOperation)
      element.operator == :minus || element.operator == :plus
    end

    def sep_str(opts = options)
      return ' ' if separator == :space
      return ',' if opts && opts[:style] == :compressed
      ', '
    end
  end
end
