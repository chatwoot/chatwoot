require 'sass/selector/simple'
require 'sass/selector/abstract_sequence'
require 'sass/selector/comma_sequence'
require 'sass/selector/pseudo'
require 'sass/selector/sequence'
require 'sass/selector/simple_sequence'

module Sass
  # A namespace for nodes in the parse tree for selectors.
  #
  # {CommaSequence} is the toplevel selector,
  # representing a comma-separated sequence of {Sequence}s,
  # such as `foo bar, baz bang`.
  # {Sequence} is the next level,
  # representing {SimpleSequence}s separated by combinators (e.g. descendant or child),
  # such as `foo bar` or `foo > bar baz`.
  # {SimpleSequence} is a sequence of selectors that all apply to a single element,
  # such as `foo.bar[attr=val]`.
  # Finally, {Simple} is the superclass of the simplest selectors,
  # such as `.foo` or `#bar`.
  module Selector
    # The base used for calculating selector specificity. The spec says this
    # should be "sufficiently high"; it's extremely unlikely that any single
    # selector sequence will contain 1,000 simple selectors.
    SPECIFICITY_BASE = 1_000

    # A parent-referencing selector (`&` in Sass).
    # The function of this is to be replaced by the parent selector
    # in the nested hierarchy.
    class Parent < Simple
      # The identifier following the `&`. `nil` indicates no suffix.
      #
      # @return [String, nil]
      attr_reader :suffix

      # @param name [String, nil] See \{#suffix}
      def initialize(suffix = nil)
        @suffix = suffix
      end

      # @see Selector#to_s
      def to_s(opts = {})
        "&" + (@suffix || '')
      end

      # Always raises an exception.
      #
      # @raise [Sass::SyntaxError] Parent selectors should be resolved before unification
      # @see Selector#unify
      def unify(sels)
        raise Sass::SyntaxError.new("[BUG] Cannot unify parent selectors.")
      end
    end

    # A class selector (e.g. `.foo`).
    class Class < Simple
      # The class name.
      #
      # @return [String]
      attr_reader :name

      # @param name [String] The class name
      def initialize(name)
        @name = name
      end

      # @see Selector#to_s
      def to_s(opts = {})
        "." + @name
      end

      # @see AbstractSequence#specificity
      def specificity
        SPECIFICITY_BASE
      end
    end

    # An id selector (e.g. `#foo`).
    class Id < Simple
      # The id name.
      #
      # @return [String]
      attr_reader :name

      # @param name [String] The id name
      def initialize(name)
        @name = name
      end

      def unique?
        true
      end

      # @see Selector#to_s
      def to_s(opts = {})
        "#" + @name
      end

      # Returns `nil` if `sels` contains an {Id} selector
      # with a different name than this one.
      #
      # @see Selector#unify
      def unify(sels)
        return if sels.any? {|sel2| sel2.is_a?(Id) && name != sel2.name}
        super
      end

      # @see AbstractSequence#specificity
      def specificity
        SPECIFICITY_BASE**2
      end
    end

    # A placeholder selector (e.g. `%foo`).
    # This exists to be replaced via `@extend`.
    # Rulesets using this selector will not be printed, but can be extended.
    # Otherwise, this acts just like a class selector.
    class Placeholder < Simple
      # The placeholder name.
      #
      # @return [String]
      attr_reader :name

      # @param name [String] The placeholder name
      def initialize(name)
        @name = name
      end

      # @see Selector#to_s
      def to_s(opts = {})
        "%" + @name
      end

      # @see AbstractSequence#specificity
      def specificity
        SPECIFICITY_BASE
      end
    end

    # A universal selector (`*` in CSS).
    class Universal < Simple
      # The selector namespace. `nil` means the default namespace, `""` means no
      # namespace, `"*"` means any namespace.
      #
      # @return [String, nil]
      attr_reader :namespace

      # @param namespace [String, nil] See \{#namespace}
      def initialize(namespace)
        @namespace = namespace
      end

      # @see Selector#to_s
      def to_s(opts = {})
        @namespace ? "#{@namespace}|*" : "*"
      end

      # Unification of a universal selector is somewhat complicated,
      # especially when a namespace is specified.
      # If there is no namespace specified
      # or any namespace is specified (namespace `"*"`),
      # then `sel` is returned without change
      # (unless it's empty, in which case `"*"` is required).
      #
      # If a namespace is specified
      # but `sel` does not specify a namespace,
      # then the given namespace is applied to `sel`,
      # either by adding this {Universal} selector
      # or applying this namespace to an existing {Element} selector.
      #
      # If both this selector *and* `sel` specify namespaces,
      # those namespaces are unified via {Simple#unify_namespaces}
      # and the unified namespace is used, if possible.
      #
      # @todo There are lots of cases that this documentation specifies;
      #   make sure we thoroughly test **all of them**.
      # @todo Keep track of whether a default namespace has been declared
      #   and handle namespace-unspecified selectors accordingly.
      # @todo If any branch of a CommaSequence ends up being just `"*"`,
      #   then all other branches should be eliminated
      #
      # @see Selector#unify
      def unify(sels)
        name =
          case sels.first
          when Universal; :universal
          when Element; sels.first.name
          else
            return [self] + sels unless namespace.nil? || namespace == '*'
            return sels unless sels.empty?
            return [self]
          end

        ns, accept = unify_namespaces(namespace, sels.first.namespace)
        return unless accept
        [name == :universal ? Universal.new(ns) : Element.new(name, ns)] + sels[1..-1]
      end

      # @see AbstractSequence#specificity
      def specificity
        0
      end
    end

    # An element selector (e.g. `h1`).
    class Element < Simple
      # The element name.
      #
      # @return [String]
      attr_reader :name

      # The selector namespace. `nil` means the default namespace, `""` means no
      # namespace, `"*"` means any namespace.
      #
      # @return [String, nil]
      attr_reader :namespace

      # @param name [String] The element name
      # @param namespace [String, nil] See \{#namespace}
      def initialize(name, namespace)
        @name = name
        @namespace = namespace
      end

      # @see Selector#to_s
      def to_s(opts = {})
        @namespace ? "#{@namespace}|#{@name}" : @name
      end

      # Unification of an element selector is somewhat complicated,
      # especially when a namespace is specified.
      # First, if `sel` contains another {Element} with a different \{#name},
      # then the selectors can't be unified and `nil` is returned.
      #
      # Otherwise, if `sel` doesn't specify a namespace,
      # or it specifies any namespace (via `"*"`),
      # then it's returned with this element selector
      # (e.g. `.foo` becomes `a.foo` or `svg|a.foo`).
      # Similarly, if this selector doesn't specify a namespace,
      # the namespace from `sel` is used.
      #
      # If both this selector *and* `sel` specify namespaces,
      # those namespaces are unified via {Simple#unify_namespaces}
      # and the unified namespace is used, if possible.
      #
      # @todo There are lots of cases that this documentation specifies;
      #   make sure we thoroughly test **all of them**.
      # @todo Keep track of whether a default namespace has been declared
      #   and handle namespace-unspecified selectors accordingly.
      #
      # @see Selector#unify
      def unify(sels)
        case sels.first
        when Universal;
        when Element; return unless name == sels.first.name
        else return [self] + sels
        end

        ns, accept = unify_namespaces(namespace, sels.first.namespace)
        return unless accept
        [Element.new(name, ns)] + sels[1..-1]
      end

      # @see AbstractSequence#specificity
      def specificity
        1
      end
    end

    # An attribute selector (e.g. `[href^="http://"]`).
    class Attribute < Simple
      # The attribute name.
      #
      # @return [Array<String, Sass::Script::Tree::Node>]
      attr_reader :name

      # The attribute namespace. `nil` means the default namespace, `""` means
      # no namespace, `"*"` means any namespace.
      #
      # @return [String, nil]
      attr_reader :namespace

      # The matching operator, e.g. `"="` or `"^="`.
      #
      # @return [String]
      attr_reader :operator

      # The right-hand side of the operator.
      #
      # @return [String]
      attr_reader :value

      # Flags for the attribute selector (e.g. `i`).
      #
      # @return [String]
      attr_reader :flags

      # @param name [String] The attribute name
      # @param namespace [String, nil] See \{#namespace}
      # @param operator [String] The matching operator, e.g. `"="` or `"^="`
      # @param value [String] See \{#value}
      # @param flags [String] See \{#flags}
      def initialize(name, namespace, operator, value, flags)
        @name = name
        @namespace = namespace
        @operator = operator
        @value = value
        @flags = flags
      end

      # @see Selector#to_s
      def to_s(opts = {})
        res = "["
        res << @namespace << "|" if @namespace
        res << @name
        res << @operator << @value if @value
        res << " " << @flags if @flags
        res << "]"
      end

      # @see AbstractSequence#specificity
      def specificity
        SPECIFICITY_BASE
      end
    end
  end
end
