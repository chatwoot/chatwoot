require 'sass/tree/node'

module Sass::Tree
  # A static node representing a Sass comment (silent or loud).
  #
  # @see Sass::Tree
  class CommentNode < Node
    # The text of the comment, not including `/*` and `*/`.
    # Interspersed with {Sass::Script::Tree::Node}s representing `#{}`-interpolation
    # if this is a loud comment.
    #
    # @return [Array<String, Sass::Script::Tree::Node>]
    attr_accessor :value

    # The text of the comment
    # after any interpolated SassScript has been resolved.
    # Only set once \{Tree::Visitors::Perform} has been run.
    #
    # @return [String]
    attr_accessor :resolved_value

    # The type of the comment. `:silent` means it's never output to CSS,
    # `:normal` means it's output in every compile mode except `:compressed`,
    # and `:loud` means it's output even in `:compressed`.
    #
    # @return [Symbol]
    attr_accessor :type

    # @param value [Array<String, Sass::Script::Tree::Node>] See \{#value}
    # @param type [Symbol] See \{#type}
    def initialize(value, type)
      @value = Sass::Util.with_extracted_values(value) {|str| normalize_indentation str}
      @type = type
      super()
    end

    # Compares the contents of two comments.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean] Whether or not this node and the other object
    #   are the same
    def ==(other)
      self.class == other.class && value == other.value && type == other.type
    end

    # Returns `true` if this is a silent comment
    # or the current style doesn't render comments.
    #
    # Comments starting with ! are never invisible (and the ! is removed from the output.)
    #
    # @return [Boolean]
    def invisible?
      case @type
      when :loud; false
      when :silent; true
      else; style == :compressed
      end
    end

    # Returns the number of lines in the comment.
    #
    # @return [Integer]
    def lines
      @value.inject(0) do |s, e|
        next s + e.count("\n") if e.is_a?(String)
        next s
      end
    end

    private

    def normalize_indentation(str)
      ind = str.split("\n").inject(str[/^[ \t]*/].split("")) do |pre, line|
        line[/^[ \t]*/].split("").zip(pre).inject([]) do |arr, (a, b)|
          break arr if a != b
          arr << a
        end
      end.join
      str.gsub(/^#{ind}/, '')
    end
  end
end
