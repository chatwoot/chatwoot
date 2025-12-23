# frozen_string_literal: true

class SassC::Script::Value::String < SassC::Script::Value

  # The Ruby value of the string.
  attr_reader :value

  # Whether this is a CSS string or a CSS identifier.
  # The difference is that strings are written with double-quotes,
  # while identifiers aren't.
  #
  # @return [Symbol] `:string` or `:identifier`
  attr_reader :type

  # Returns the quoted string representation of `contents`.
  #
  # @options opts :quote [String]
  #   The preferred quote style for quoted strings. If `:none`, strings are
  #   always emitted unquoted. If `nil`, quoting is determined automatically.
  # @options opts :sass [String]
  #   Whether to quote strings for Sass source, as opposed to CSS. Defaults to `false`.
  def self.quote(contents, opts = {})
    quote = opts[:quote]

    # Short-circuit if there are no characters that need quoting.
    unless contents =~ /[\n\\"']|\#\{/
      quote ||= '"'
      return "#{quote}#{contents}#{quote}"
    end

    if quote.nil?
      if contents.include?('"')
        if contents.include?("'")
          quote = '"'
        else
          quote = "'"
        end
      else
        quote = '"'
      end
    end

    # Replace single backslashes with multiples.
    contents = contents.gsub("\\", "\\\\\\\\")

    # Escape interpolation.
    contents = contents.gsub('#{', "\\\#{") if opts[:sass]

    if quote == '"'
      contents = contents.gsub('"', "\\\"")
    else
      contents = contents.gsub("'", "\\'")
    end

    contents = contents.gsub(/\n(?![a-fA-F0-9\s])/, "\\a").gsub("\n", "\\a ")
    "#{quote}#{contents}#{quote}"
  end

  # Creates a new string.
  #
  # @param value [String] See \{#value}
  # @param type [Symbol] See \{#type}
  # @param deprecated_interp_equivalent [String?]
  #   If this was created via a potentially-deprecated string interpolation,
  #   this is the replacement expression that should be suggested to the user.
  def initialize(value, type = :identifier)
    super(value)
    @type = type
  end

  # @see Value#plus
  def plus(other)
    if other.is_a?(SassC::Script::Value::String)
      other_value = other.value
    else
      other_value = other.to_s(:quote => :none)
    end
    SassC::Script::Value::String.new(value + other_value, type)
  end

  # @see Value#to_s
  def to_s(opts = {})
    return @value.gsub(/\n\s*/, ' ') if opts[:quote] == :none || @type == :identifier
    self.class.quote(value, opts)
  end

  # @see Value#to_sass
  def to_sass(opts = {})
    to_s(opts.merge(:sass => true))
  end

  def inspect
    String.quote(value)
  end

end
