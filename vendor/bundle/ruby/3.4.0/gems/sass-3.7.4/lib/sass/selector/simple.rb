module Sass
  module Selector
    # The abstract superclass for simple selectors
    # (that is, those that don't compose multiple selectors).
    class Simple
      # The line of the Sass template on which this selector was declared.
      #
      # @return [Integer]
      attr_accessor :line

      # The name of the file in which this selector was declared,
      # or `nil` if it was not declared in a file (e.g. on stdin).
      #
      # @return [String, nil]
      attr_accessor :filename

      # Whether only one instance of this simple selector is allowed in a given
      # complex selector.
      #
      # @return [Boolean]
      def unique?
        false
      end

      # @see #to_s
      #
      # @return [String]
      def inspect
        to_s
      end

      # Returns the selector string.
      #
      # @param opts [Hash] rendering options.
      # @option opts [Symbol] :style The css rendering style.
      # @return [String]
      def to_s(opts = {})
        Sass::Util.abstract(self)
      end

      # Returns a hash code for this selector object.
      #
      # By default, this is based on the value of \{#to\_a},
      # so if that contains information irrelevant to the identity of the selector,
      # this should be overridden.
      #
      # @return [Integer]
      def hash
        @_hash ||= equality_key.hash
      end

      # Checks equality between this and another object.
      #
      # By default, this is based on the value of \{#to\_a},
      # so if that contains information irrelevant to the identity of the selector,
      # this should be overridden.
      #
      # @param other [Object] The object to test equality against
      # @return [Boolean] Whether or not this is equal to `other`
      def eql?(other)
        other.class == self.class && other.hash == hash && other.equality_key == equality_key
      end
      alias_method :==, :eql?

      # Unifies this selector with a {SimpleSequence}'s {SimpleSequence#members members array},
      # returning another `SimpleSequence` members array
      # that matches both this selector and the input selector.
      #
      # By default, this just appends this selector to the end of the array
      # (or returns the original array if this selector already exists in it).
      #
      # @param sels [Array<Simple>] A {SimpleSequence}'s {SimpleSequence#members members array}
      # @return [Array<Simple>, nil] A {SimpleSequence} {SimpleSequence#members members array}
      #   matching both `sels` and this selector,
      #   or `nil` if this is impossible (e.g. unifying `#foo` and `#bar`)
      # @raise [Sass::SyntaxError] If this selector cannot be unified.
      #   This will only ever occur when a dynamic selector,
      #   such as {Parent} or {Interpolation}, is used in unification.
      #   Since these selectors should be resolved
      #   by the time extension and unification happen,
      #   this exception will only ever be raised as a result of programmer error
      def unify(sels)
        return sels.first.unify([self]) if sels.length == 1 && sels.first.is_a?(Universal)
        return sels if sels.any? {|sel2| eql?(sel2)}
        if !is_a?(Pseudo) || (sels.last.is_a?(Pseudo) && sels.last.type == :element)
          _, i = sels.each_with_index.find {|sel, _| sel.is_a?(Pseudo)}
        end
        return sels + [self] unless i
        sels[0...i] + [self] + sels[i..-1]
      end

      protected

      # Returns the key used for testing whether selectors are equal.
      #
      # This is a cached version of \{#to\_s}.
      #
      # @return [String]
      def equality_key
        @equality_key ||= to_s
      end

      # Unifies two namespaces,
      # returning a namespace that works for both of them if possible.
      #
      # @param ns1 [String, nil] The first namespace.
      #   `nil` means none specified, e.g. `foo`.
      #   The empty string means no namespace specified, e.g. `|foo`.
      #   `"*"` means any namespace is allowed, e.g. `*|foo`.
      # @param ns2 [String, nil] The second namespace. See `ns1`.
      # @return [Array(String or nil, Boolean)]
      #   The first value is the unified namespace, or `nil` for no namespace.
      #   The second value is whether or not a namespace that works for both inputs
      #   could be found at all.
      #   If the second value is `false`, the first should be ignored.
      def unify_namespaces(ns1, ns2)
        return ns2, true if ns1 == '*'
        return ns1, true if ns2 == '*'
        return nil, false unless ns1 == ns2
        [ns1, true]
      end
    end
  end
end
