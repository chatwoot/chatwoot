module Sass::Script::Value
  # A SassScript object representing a map from keys to values. Both keys and
  # values can be any SassScript object.
  class Map < Base
    # The Ruby hash containing the contents of this map.
    #
    # @return [Hash<Node, Node>]
    attr_reader :value
    alias_method :to_h, :value

    # Creates a new map.
    #
    # @param hash [Hash<Node, Node>]
    def initialize(hash)
      super(hash)
    end

    # @see Value#options=
    def options=(options)
      super
      value.each do |k, v|
        k.options = options
        v.options = options
      end
    end

    # @see Value#separator
    def separator
      :comma unless value.empty?
    end

    # @see Value#to_a
    def to_a
      value.map do |k, v|
        list = List.new([k, v], separator: :space)
        list.options = options
        list
      end
    end

    # @see Value#eq
    def eq(other)
      Bool.new(other.is_a?(Map) && value == other.value)
    end

    def hash
      @hash ||= value.hash
    end

    # @see Value#to_s
    def to_s(opts = {})
      raise Sass::SyntaxError.new("#{inspect} isn't a valid CSS value.")
    end

    def to_sass(opts = {})
      return "()" if value.empty?

      to_sass = lambda do |value|
        if value.is_a?(List) && value.separator == :comma
          "(#{value.to_sass(opts)})"
        else
          value.to_sass(opts)
        end
      end

      "(#{value.map {|(k, v)| "#{to_sass[k]}: #{to_sass[v]}"}.join(', ')})"
    end
    alias_method :inspect, :to_sass
  end
end
