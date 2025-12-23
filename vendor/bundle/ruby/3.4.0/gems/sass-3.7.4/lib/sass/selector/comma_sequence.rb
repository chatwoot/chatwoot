module Sass
  module Selector
    # A comma-separated sequence of selectors.
    class CommaSequence < AbstractSequence
      @@compound_extend_deprecation = Sass::Deprecation.new

      # The comma-separated selector sequences
      # represented by this class.
      #
      # @return [Array<Sequence>]
      attr_reader :members

      # @param seqs [Array<Sequence>] See \{#members}
      def initialize(seqs)
        @members = seqs
      end

      # Resolves the {Parent} selectors within this selector
      # by replacing them with the given parent selector,
      # handling commas appropriately.
      #
      # @param super_cseq [CommaSequence] The parent selector
      # @param implicit_parent [Boolean] Whether the the parent
      #   selector should automatically be prepended to the resolved
      #   selector if it contains no parent refs.
      # @return [CommaSequence] This selector, with parent references resolved
      # @raise [Sass::SyntaxError] If a parent selector is invalid
      def resolve_parent_refs(super_cseq, implicit_parent = true)
        if super_cseq.nil?
          if contains_parent_ref?
            raise Sass::SyntaxError.new(
              "Base-level rules cannot contain the parent-selector-referencing character '&'.")
          end
          return self
        end

        CommaSequence.new(Sass::Util.flatten_vertically(@members.map do |seq|
          seq.resolve_parent_refs(super_cseq, implicit_parent).members
        end))
      end

      # Returns whether there's a {Parent} selector anywhere in this sequence.
      #
      # @return [Boolean]
      def contains_parent_ref?
        @members.any? {|sel| sel.contains_parent_ref?}
      end

      # Non-destrucively extends this selector with the extensions specified in a hash
      # (which should come from {Sass::Tree::Visitors::Cssize}).
      #
      # @todo Link this to the reference documentation on `@extend`
      #   when such a thing exists.
      #
      # @param extends [Sass::Util::SubsetMap{Selector::Simple =>
      #                                       Sass::Tree::Visitors::Cssize::Extend}]
      #   The extensions to perform on this selector
      # @param parent_directives [Array<Sass::Tree::DirectiveNode>]
      #   The directives containing this selector.
      # @param replace [Boolean]
      #   Whether to replace the original selector entirely or include
      #   it in the result.
      # @param seen [Set<Array<Selector::Simple>>]
      #   The set of simple sequences that are currently being replaced.
      # @param original [Boolean]
      #   Whether this is the original selector being extended, as opposed to
      #   the result of a previous extension that's being re-extended.
      # @return [CommaSequence] A copy of this selector,
      #   with extensions made according to `extends`
      def do_extend(extends, parent_directives = [], replace = false, seen = Set.new,
          original = true)
        CommaSequence.new(members.map do |seq|
          seq.do_extend(extends, parent_directives, replace, seen, original)
        end.flatten)
      end

      # Returns whether or not this selector matches all elements
      # that the given selector matches (as well as possibly more).
      #
      # @example
      #   (.foo).superselector?(.foo.bar) #=> true
      #   (.foo).superselector?(.bar) #=> false
      # @param cseq [CommaSequence]
      # @return [Boolean]
      def superselector?(cseq)
        cseq.members.all? {|seq1| members.any? {|seq2| seq2.superselector?(seq1)}}
      end

      # Populates a subset map that can then be used to extend
      # selectors. This registers an extension with this selector as
      # the extender and `extendee` as the extendee.
      #
      # @param extends [Sass::Util::SubsetMap{Selector::Simple =>
      #                                       Sass::Tree::Visitors::Cssize::Extend}]
      #   The subset map representing the extensions to perform.
      # @param extendee [CommaSequence] The selector being extended.
      # @param extend_node [Sass::Tree::ExtendNode]
      #   The node that caused this extension.
      # @param parent_directives [Array<Sass::Tree::DirectiveNode>]
      #   The parent directives containing `extend_node`.
      # @param allow_compound_target [Boolean]
      #   Whether `extendee` is allowed to contain compound selectors.
      # @raise [Sass::SyntaxError] if this extension is invalid.
      def populate_extends(extends, extendee, extend_node = nil, parent_directives = [],
          allow_compound_target = false)
        extendee.members.each do |seq|
          if seq.members.size > 1
            raise Sass::SyntaxError.new("Can't extend #{seq}: can't extend nested selectors")
          end

          sseq = seq.members.first
          if !sseq.is_a?(Sass::Selector::SimpleSequence)
            raise Sass::SyntaxError.new("Can't extend #{seq}: invalid selector")
          elsif sseq.members.any? {|ss| ss.is_a?(Sass::Selector::Parent)}
            raise Sass::SyntaxError.new("Can't extend #{seq}: can't extend parent selectors")
          end

          sel = sseq.members
          if !allow_compound_target && sel.length > 1
            @@compound_extend_deprecation.warn(sseq.filename, sseq.line, <<WARNING)
Extending a compound selector, #{sseq}, is deprecated and will not be supported in a future release.
Consider "@extend #{sseq.members.join(', ')}" instead.
See http://bit.ly/ExtendCompound for details.
WARNING
          end

          members.each do |member|
            unless member.members.last.is_a?(Sass::Selector::SimpleSequence)
              raise Sass::SyntaxError.new("#{member} can't extend: invalid selector")
            end

            extends[sel] = Sass::Tree::Visitors::Cssize::Extend.new(
              member, sel, extend_node, parent_directives, false)
          end
        end
      end

      # Unifies this with another comma selector to produce a selector
      # that matches (a subset of) the intersection of the two inputs.
      #
      # @param other [CommaSequence]
      # @return [CommaSequence, nil] The unified selector, or nil if unification failed.
      # @raise [Sass::SyntaxError] If this selector cannot be unified.
      #   This will only ever occur when a dynamic selector,
      #   such as {Parent} or {Interpolation}, is used in unification.
      #   Since these selectors should be resolved
      #   by the time extension and unification happen,
      #   this exception will only ever be raised as a result of programmer error
      def unify(other)
        results = members.map {|seq1| other.members.map {|seq2| seq1.unify(seq2)}}.flatten.compact
        results.empty? ? nil : CommaSequence.new(results.map {|cseq| cseq.members}.flatten)
      end

      # Returns a SassScript representation of this selector.
      #
      # @return [Sass::Script::Value::List]
      def to_sass_script
        Sass::Script::Value::List.new(members.map do |seq|
          Sass::Script::Value::List.new(seq.members.map do |component|
            next if component == "\n"
            Sass::Script::Value::String.new(component.to_s)
          end.compact, separator: :space)
        end, separator: :comma)
      end

      # Returns a string representation of the sequence.
      # This is basically the selector string.
      #
      # @return [String]
      def inspect
        members.map {|m| m.inspect}.join(", ")
      end

      # @see AbstractSequence#to_s
      def to_s(opts = {})
        @members.map do |m|
          next if opts[:placeholder] == false && m.invisible?
          m.to_s(opts)
        end.compact.
          join(opts[:style] == :compressed ? "," : ", ").
          gsub(", \n", ",\n")
      end

      private

      def _hash
        members.hash
      end

      def _eql?(other)
        other.class == self.class && other.members.eql?(members)
      end
    end
  end
end
