# frozen_string_literal: true

module RuboCop
  module AST
    # Common predicates for nodes that reference method identifiers:
    # `send`, `csend`, `def`, `defs`, `super`, `zsuper`
    #
    # @note this mixin expects `#method_name` and `#receiver` to be implemented
    module MethodIdentifierPredicates # rubocop:disable Metrics/ModuleLength
      ENUMERATOR_METHODS = %i[collect collect_concat detect downto each
                              find find_all find_index inject loop map!
                              map reduce reject reject! reverse_each select
                              select! times upto].to_set.freeze
      private_constant :ENUMERATOR_METHODS

      ENUMERABLE_METHODS = (Enumerable.instance_methods + [:each]).to_set.freeze
      private_constant :ENUMERABLE_METHODS

      # http://phrogz.net/programmingruby/language.html#table_18.4
      OPERATOR_METHODS = %i[| ^ & <=> == === =~ > >= < <= << >> + - * /
                            % ** ~ +@ -@ !@ ~@ [] []= ! != !~ `].to_set.freeze
      private_constant :OPERATOR_METHODS

      NONMUTATING_BINARY_OPERATOR_METHODS = %i[* / % + - == === != < > <= >= <=>].to_set.freeze
      private_constant :NONMUTATING_BINARY_OPERATOR_METHODS
      NONMUTATING_UNARY_OPERATOR_METHODS = %i[+@ -@ ~ !].to_set.freeze
      private_constant :NONMUTATING_UNARY_OPERATOR_METHODS
      NONMUTATING_OPERATOR_METHODS = (NONMUTATING_BINARY_OPERATOR_METHODS +
        NONMUTATING_UNARY_OPERATOR_METHODS).freeze
      private_constant :NONMUTATING_OPERATOR_METHODS

      NONMUTATING_ARRAY_METHODS = %i[
        all? any? assoc at bsearch bsearch_index collect
        combination compact count cycle deconstruct difference
        dig drop drop_while each each_index empty? eql?
        fetch filter find_index first flatten hash
        include? index inspect intersection join
        last length map max min minmax none? one? pack
        permutation product rassoc reject
        repeated_combination repeated_permutation reverse
        reverse_each rindex rotate sample select shuffle
        size slice sort sum take take_while
        to_a to_ary to_h to_s transpose union uniq
        values_at zip |
      ].to_set.freeze
      private_constant :NONMUTATING_ARRAY_METHODS

      NONMUTATING_HASH_METHODS = %i[
        any? assoc compact dig each each_key each_pair
        each_value empty? eql? fetch fetch_values filter
        flatten has_key? has_value? hash include? inspect
        invert key key? keys? length member? merge rassoc
        rehash reject select size slice to_a to_h to_hash
        to_proc to_s transform_keys transform_values value?
        values values_at
      ].to_set.freeze
      private_constant :NONMUTATING_HASH_METHODS

      NONMUTATING_STRING_METHODS = %i[
        ascii_only? b bytes bytesize byteslice capitalize
        casecmp casecmp? center chars chomp chop chr codepoints
        count crypt delete delete_prefix delete_suffix
        downcase dump each_byte each_char each_codepoint
        each_grapheme_cluster each_line empty? encode encoding
        end_with? eql? getbyte grapheme_clusters gsub hash
        hex include index inspect intern length lines ljust lstrip
        match match? next oct ord partition reverse rindex rjust
        rpartition rstrip scan scrub size slice squeeze start_with?
        strip sub succ sum swapcase to_a to_c to_f to_i to_r to_s
        to_str to_sym tr tr_s unicode_normalize unicode_normalized?
        unpack unpack1 upcase upto valid_encoding?
      ].to_set.freeze
      private_constant :NONMUTATING_STRING_METHODS

      # Checks whether the method name matches the argument.
      #
      # @param [Symbol, String] name the method name to check for
      # @return [Boolean] whether the method name matches the argument
      def method?(name)
        method_name == name.to_sym
      end

      # Checks whether the method is an operator method.
      #
      # @return [Boolean] whether the method is an operator
      def operator_method?
        OPERATOR_METHODS.include?(method_name)
      end

      # Checks whether the method is a nonmutating binary operator method.
      #
      # @return [Boolean] whether the method is a nonmutating binary operator method
      def nonmutating_binary_operator_method?
        NONMUTATING_BINARY_OPERATOR_METHODS.include?(method_name)
      end

      # Checks whether the method is a nonmutating unary operator method.
      #
      # @return [Boolean] whether the method is a nonmutating unary operator method
      def nonmutating_unary_operator_method?
        NONMUTATING_UNARY_OPERATOR_METHODS.include?(method_name)
      end

      # Checks whether the method is a nonmutating operator method.
      #
      # @return [Boolean] whether the method is a nonmutating operator method
      def nonmutating_operator_method?
        NONMUTATING_OPERATOR_METHODS.include?(method_name)
      end

      # Checks whether the method is a nonmutating Array method.
      #
      # @return [Boolean] whether the method is a nonmutating Array method
      def nonmutating_array_method?
        NONMUTATING_ARRAY_METHODS.include?(method_name)
      end

      # Checks whether the method is a nonmutating Hash method.
      #
      # @return [Boolean] whether the method is a nonmutating Hash method
      def nonmutating_hash_method?
        NONMUTATING_HASH_METHODS.include?(method_name)
      end

      # Checks whether the method is a nonmutating String method.
      #
      # @return [Boolean] whether the method is a nonmutating String method
      def nonmutating_string_method?
        NONMUTATING_STRING_METHODS.include?(method_name)
      end

      # Checks whether the method is a comparison method.
      #
      # @return [Boolean] whether the method is a comparison
      def comparison_method?
        Node::COMPARISON_OPERATORS.include?(method_name)
      end

      # Checks whether the method is an assignment method.
      #
      # @return [Boolean] whether the method is an assignment
      def assignment_method?
        !comparison_method? && method_name.to_s.end_with?('=')
      end

      # Checks whether the method is an enumerator method.
      #
      # @return [Boolean] whether the method is an enumerator
      def enumerator_method?
        ENUMERATOR_METHODS.include?(method_name) ||
          method_name.to_s.start_with?('each_')
      end

      # Checks whether the method is an Enumerable method.
      #
      # @return [Boolean] whether the method is an Enumerable method
      def enumerable_method?
        ENUMERABLE_METHODS.include?(method_name)
      end

      # Checks whether the method is a predicate method.
      #
      # @return [Boolean] whether the method is a predicate method
      def predicate_method?
        method_name.to_s.end_with?('?')
      end

      # Checks whether the method is a bang method.
      #
      # @return [Boolean] whether the method is a bang method
      def bang_method?
        method_name.to_s.end_with?('!')
      end

      # Checks whether the method is a camel case method,
      # e.g. `Integer()`.
      #
      # @return [Boolean] whether the method is a camel case method
      def camel_case_method?
        method_name.to_s =~ /\A[A-Z]/
      end

      # Checks whether the *explicit* receiver of this node is `self`.
      #
      # @return [Boolean] whether the receiver of this node is `self`
      def self_receiver?
        receiver&.self_type?
      end

      # Checks whether the *explicit* receiver of node is a `const` node.
      #
      # @return [Boolean] whether the receiver of this node is a `const` node
      def const_receiver?
        receiver&.const_type?
      end

      # Checks whether this is a negation method, i.e. `!` or keyword `not`.
      #
      # @return [Boolean] whether this method is a negation method
      def negation_method?
        receiver && method_name == :!
      end

      # Checks whether this is a prefix not method, e.g. `not foo`.
      #
      # @return [Boolean] whether this method is a prefix not
      def prefix_not?
        negation_method? && loc.selector.is?('not')
      end

      # Checks whether this is a prefix bang method, e.g. `!foo`.
      #
      # @return [Boolean] whether this method is a prefix bang
      def prefix_bang?
        negation_method? && loc.selector.is?('!')
      end
    end
  end
end
