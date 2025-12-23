# frozen_string_literal: true

# Here we are reopening the prism module to provide methods on nodes that aren't
# templated and are meant as convenience methods.
module Prism
  class Node
    def deprecated(*replacements) # :nodoc:
      location = caller_locations(1, 1)
      location = location[0].label if location
      suggest = replacements.map { |replacement| "#{self.class}##{replacement}" }

      warn(<<~MSG, category: :deprecated)
        [deprecation]: #{self.class}##{location} is deprecated and will be \
        removed in the next major version. Use #{suggest.join("/")} instead.
        #{(caller(1, 3) || []).join("\n")}
      MSG
    end
  end

  module RegularExpressionOptions # :nodoc:
    # Returns a numeric value that represents the flags that were used to create
    # the regular expression.
    def options
      o = 0
      o |= Regexp::IGNORECASE if flags.anybits?(RegularExpressionFlags::IGNORE_CASE)
      o |= Regexp::EXTENDED if flags.anybits?(RegularExpressionFlags::EXTENDED)
      o |= Regexp::MULTILINE if flags.anybits?(RegularExpressionFlags::MULTI_LINE)
      o |= Regexp::FIXEDENCODING if flags.anybits?(RegularExpressionFlags::EUC_JP | RegularExpressionFlags::WINDOWS_31J | RegularExpressionFlags::UTF_8)
      o |= Regexp::NOENCODING if flags.anybits?(RegularExpressionFlags::ASCII_8BIT)
      o
    end
  end

  class InterpolatedMatchLastLineNode < Node
    include RegularExpressionOptions
  end

  class InterpolatedRegularExpressionNode < Node
    include RegularExpressionOptions
  end

  class MatchLastLineNode < Node
    include RegularExpressionOptions
  end

  class RegularExpressionNode < Node
    include RegularExpressionOptions
  end

  private_constant :RegularExpressionOptions

  module HeredocQuery # :nodoc:
    # Returns true if this node was represented as a heredoc in the source code.
    def heredoc?
      opening&.start_with?("<<")
    end
  end

  class InterpolatedStringNode < Node
    include HeredocQuery
  end

  class InterpolatedXStringNode < Node
    include HeredocQuery
  end

  class StringNode < Node
    include HeredocQuery

    # Occasionally it's helpful to treat a string as if it were interpolated so
    # that there's a consistent interface for working with strings.
    def to_interpolated
      InterpolatedStringNode.new(
        source,
        -1,
        location,
        frozen? ? InterpolatedStringNodeFlags::FROZEN : 0,
        opening_loc,
        [copy(location: content_loc, opening_loc: nil, closing_loc: nil)],
        closing_loc
      )
    end
  end

  class XStringNode < Node
    include HeredocQuery

    # Occasionally it's helpful to treat a string as if it were interpolated so
    # that there's a consistent interface for working with strings.
    def to_interpolated
      InterpolatedXStringNode.new(
        source,
        -1,
        location,
        flags,
        opening_loc,
        [StringNode.new(source, node_id, content_loc, 0, nil, content_loc, nil, unescaped)],
        closing_loc
      )
    end
  end

  private_constant :HeredocQuery

  class ImaginaryNode < Node
    # Returns the value of the node as a Ruby Complex.
    def value
      Complex(0, numeric.value)
    end
  end

  class RationalNode < Node
    # Returns the value of the node as a Ruby Rational.
    def value
      Rational(numerator, denominator)
    end

    # Returns the value of the node as an IntegerNode or a FloatNode. This
    # method is deprecated in favor of #value or #numerator/#denominator.
    def numeric
      deprecated("value", "numerator", "denominator")

      if denominator == 1
        IntegerNode.new(source, -1, location.chop, flags, numerator)
      else
        FloatNode.new(source, -1, location.chop, 0, numerator.to_f / denominator)
      end
    end
  end

  class ConstantReadNode < Node
    # Returns the list of parts for the full name of this constant.
    # For example: [:Foo]
    def full_name_parts
      [name]
    end

    # Returns the full name of this constant. For example: "Foo"
    def full_name
      name.to_s
    end
  end

  class ConstantWriteNode < Node
    # Returns the list of parts for the full name of this constant.
    # For example: [:Foo]
    def full_name_parts
      [name]
    end

    # Returns the full name of this constant. For example: "Foo"
    def full_name
      name.to_s
    end
  end

  class ConstantPathNode < Node
    # An error class raised when dynamic parts are found while computing a
    # constant path's full name. For example:
    # Foo::Bar::Baz -> does not raise because all parts of the constant path are
    # simple constants
    # var::Bar::Baz -> raises because the first part of the constant path is a
    # local variable
    class DynamicPartsInConstantPathError < StandardError; end

    # An error class raised when missing nodes are found while computing a
    # constant path's full name. For example:
    # Foo:: -> raises because the constant path is missing the last part
    class MissingNodesInConstantPathError < StandardError; end

    # Returns the list of parts for the full name of this constant path.
    # For example: [:Foo, :Bar]
    def full_name_parts
      parts = [] #: Array[Symbol]
      current = self #: node?

      while current.is_a?(ConstantPathNode)
        name = current.name
        if name.nil?
          raise MissingNodesInConstantPathError, "Constant path contains missing nodes. Cannot compute full name"
        end

        parts.unshift(name)
        current = current.parent
      end

      if !current.is_a?(ConstantReadNode) && !current.nil?
        raise DynamicPartsInConstantPathError, "Constant path contains dynamic parts. Cannot compute full name"
      end

      parts.unshift(current&.name || :"")
    end

    # Returns the full name of this constant path. For example: "Foo::Bar"
    def full_name
      full_name_parts.join("::")
    end

    # Previously, we had a child node on this class that contained either a
    # constant read or a missing node. To not cause a breaking change, we
    # continue to supply that API.
    def child
      deprecated("name", "name_loc")

      if name
        ConstantReadNode.new(source, -1, name_loc, 0, name)
      else
        MissingNode.new(source, -1, location, 0)
      end
    end
  end

  class ConstantPathTargetNode < Node
    # Returns the list of parts for the full name of this constant path.
    # For example: [:Foo, :Bar]
    def full_name_parts
      parts =
        case parent
        when ConstantPathNode, ConstantReadNode
          parent.full_name_parts
        when nil
          [:""]
        else
          # e.g. self::Foo, (var)::Bar = baz
          raise ConstantPathNode::DynamicPartsInConstantPathError, "Constant target path contains dynamic parts. Cannot compute full name"
        end

      if name.nil?
        raise ConstantPathNode::MissingNodesInConstantPathError, "Constant target path contains missing nodes. Cannot compute full name"
      end

      parts.push(name)
    end

    # Returns the full name of this constant path. For example: "Foo::Bar"
    def full_name
      full_name_parts.join("::")
    end

    # Previously, we had a child node on this class that contained either a
    # constant read or a missing node. To not cause a breaking change, we
    # continue to supply that API.
    def child
      deprecated("name", "name_loc")

      if name
        ConstantReadNode.new(source, -1, name_loc, 0, name)
      else
        MissingNode.new(source, -1, location, 0)
      end
    end
  end

  class ConstantTargetNode < Node
    # Returns the list of parts for the full name of this constant.
    # For example: [:Foo]
    def full_name_parts
      [name]
    end

    # Returns the full name of this constant. For example: "Foo"
    def full_name
      name.to_s
    end
  end

  class ParametersNode < Node
    # Mirrors the Method#parameters method.
    def signature
      names = [] #: Array[[Symbol, Symbol] | [Symbol]]

      requireds.each do |param|
        names << (param.is_a?(MultiTargetNode) ? [:req] : [:req, param.name])
      end

      optionals.each { |param| names << [:opt, param.name] }

      if rest && rest.is_a?(RestParameterNode)
        names << [:rest, rest.name || :*]
      end

      posts.each do |param|
        case param
        when MultiTargetNode
          names << [:req]
        when NoKeywordsParameterNode, KeywordRestParameterNode, ForwardingParameterNode
          # Invalid syntax, e.g. "def f(**nil, ...)" moves the NoKeywordsParameterNode to posts
          raise "Invalid syntax"
        else
          names << [:req, param.name]
        end
      end

      # Regardless of the order in which the keywords were defined, the required
      # keywords always come first followed by the optional keywords.
      keyopt = [] #: Array[OptionalKeywordParameterNode]
      keywords.each do |param|
        if param.is_a?(OptionalKeywordParameterNode)
          keyopt << param
        else
          names << [:keyreq, param.name]
        end
      end

      keyopt.each { |param| names << [:key, param.name] }

      case keyword_rest
      when ForwardingParameterNode
        names.concat([[:rest, :*], [:keyrest, :**], [:block, :&]])
      when KeywordRestParameterNode
        names << [:keyrest, keyword_rest.name || :**]
      when NoKeywordsParameterNode
        names << [:nokey]
      end

      names << [:block, block.name || :&] if block
      names
    end
  end

  class CallNode < Node
    # When a call node has the attribute_write flag set, it means that the call
    # is using the attribute write syntax. This is either a method call to []=
    # or a method call to a method that ends with =. Either way, the = sign is
    # present in the source.
    #
    # Prism returns the message_loc _without_ the = sign attached, because there
    # can be any amount of space between the message and the = sign. However,
    # sometimes you want the location of the full message including the inner
    # space and the = sign. This method provides that.
    def full_message_loc
      attribute_write? ? message_loc&.adjoin("=") : message_loc
    end
  end

  class CallOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    def operator
      deprecated("binary_operator")
      binary_operator
    end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    def operator_loc
      deprecated("binary_operator_loc")
      binary_operator_loc
    end
  end

  class ClassVariableOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    def operator
      deprecated("binary_operator")
      binary_operator
    end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    def operator_loc
      deprecated("binary_operator_loc")
      binary_operator_loc
    end
  end

  class ConstantOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    def operator
      deprecated("binary_operator")
      binary_operator
    end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    def operator_loc
      deprecated("binary_operator_loc")
      binary_operator_loc
    end
  end

  class ConstantPathOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    def operator
      deprecated("binary_operator")
      binary_operator
    end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    def operator_loc
      deprecated("binary_operator_loc")
      binary_operator_loc
    end
  end

  class GlobalVariableOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    def operator
      deprecated("binary_operator")
      binary_operator
    end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    def operator_loc
      deprecated("binary_operator_loc")
      binary_operator_loc
    end
  end

  class IndexOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    def operator
      deprecated("binary_operator")
      binary_operator
    end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    def operator_loc
      deprecated("binary_operator_loc")
      binary_operator_loc
    end
  end

  class InstanceVariableOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    def operator
      deprecated("binary_operator")
      binary_operator
    end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    def operator_loc
      deprecated("binary_operator_loc")
      binary_operator_loc
    end
  end

  class LocalVariableOperatorWriteNode < Node
    # Returns the binary operator used to modify the receiver. This method is
    # deprecated in favor of #binary_operator.
    def operator
      deprecated("binary_operator")
      binary_operator
    end

    # Returns the location of the binary operator used to modify the receiver.
    # This method is deprecated in favor of #binary_operator_loc.
    def operator_loc
      deprecated("binary_operator_loc")
      binary_operator_loc
    end
  end

  class CaseMatchNode < Node
    # Returns the else clause of the case match node. This method is deprecated
    # in favor of #else_clause.
    def consequent
      deprecated("else_clause")
      else_clause
    end
  end

  class CaseNode < Node
    # Returns the else clause of the case node. This method is deprecated in
    # favor of #else_clause.
    def consequent
      deprecated("else_clause")
      else_clause
    end
  end

  class IfNode < Node
    # Returns the subsequent if/elsif/else clause of the if node. This method is
    # deprecated in favor of #subsequent.
    def consequent
      deprecated("subsequent")
      subsequent
    end
  end

  class RescueNode < Node
    # Returns the subsequent rescue clause of the rescue node. This method is
    # deprecated in favor of #subsequent.
    def consequent
      deprecated("subsequent")
      subsequent
    end
  end

  class UnlessNode < Node
    # Returns the else clause of the unless node. This method is deprecated in
    # favor of #else_clause.
    def consequent
      deprecated("else_clause")
      else_clause
    end
  end
end
