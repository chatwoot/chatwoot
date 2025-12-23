# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `regexp` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `regexp` nodes within RuboCop.
    class RegexpNode < Node
      OPTIONS = {
        x: Regexp::EXTENDED,
        i: Regexp::IGNORECASE,
        m: Regexp::MULTILINE,
        n: Regexp::NOENCODING,
        u: Regexp::FIXEDENCODING,
        o: 0
      }.freeze
      private_constant :OPTIONS

      # @return [Regexp] a regexp of this node
      def to_regexp
        Regexp.new(content, options)
      end

      # @return [RuboCop::AST::Node] a regopt node
      def regopt
        children.last
      end

      # NOTE: The 'o' option is ignored.
      #
      # @return [Integer] the Regexp option bits as returned by Regexp#options
      def options
        regopt.children.map { |opt| OPTIONS.fetch(opt) }.inject(0, :|)
      end

      # @return [String] a string of regexp content
      def content
        children.select(&:str_type?).map(&:str_content).join
      end

      # @return [Bool] if the regexp is a /.../ literal
      def slash_literal?
        loc.begin.source == '/'
      end

      # @return [Bool] if the regexp is a %r{...} literal (using any delimiters)
      def percent_r_literal?
        !slash_literal?
      end

      # @return [String] the regexp delimiters (without %r)
      def delimiters
        [loc.begin.source[-1], loc.end.source[0]]
      end

      # @return [Bool] if char is one of the delimiters
      def delimiter?(char)
        delimiters.include?(char)
      end

      # @return [Bool] if regexp contains interpolation
      def interpolation?
        children.any?(&:begin_type?)
      end

      # @return [Bool] if regexp uses the multiline regopt
      def multiline_mode?
        regopt_include?(:m)
      end

      # @return [Bool] if regexp uses the extended regopt
      def extended?
        regopt_include?(:x)
      end

      # @return [Bool] if regexp uses the ignore-case regopt
      def ignore_case?
        regopt_include?(:i)
      end

      # @return [Bool] if regexp uses the single-interpolation regopt
      def single_interpolation?
        regopt_include?(:o)
      end

      # @return [Bool] if regexp uses the no-encoding regopt
      def no_encoding?
        regopt_include?(:n)
      end

      # @return [Bool] if regexp uses the fixed-encoding regopt
      def fixed_encoding?
        regopt_include?(:u)
      end

      private

      def regopt_include?(option)
        regopt.children.include?(option)
      end
    end
  end
end
