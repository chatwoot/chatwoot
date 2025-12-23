# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Checks that predicate method names end with a question mark and
      # do not start with a forbidden prefix.
      #
      # A method is determined to be a predicate method if its name starts with
      # one of the prefixes listed in the `NamePrefix` configuration. The list
      # defaults to `is_`, `has_`, and `have_` but may be overridden.
      #
      # Predicate methods must end with a question mark.
      #
      # When `ForbiddenPrefixes` is also set (as it is by default), predicate
      # methods which begin with a forbidden prefix are not allowed, even if
      # they end with a `?`. These methods should be changed to remove the
      # prefix.
      #
      # When `UseSorbetSigs` set to true (optional), the cop will only report
      # offenses if the method has a Sorbet `sig` with a return type of
      # `T::Boolean`. Dynamic methods are not supported with this configuration.
      #
      # @example NamePrefix: ['is_', 'has_', 'have_'] (default)
      #   # bad
      #   def is_even(value)
      #   end
      #
      #   # When ForbiddenPrefixes: ['is_', 'has_', 'have_'] (default)
      #   # good
      #   def even?(value)
      #   end
      #
      #   # When ForbiddenPrefixes: []
      #   # good
      #   def is_even?(value)
      #   end
      #
      # @example NamePrefix: ['seems_to_be_']
      #   # bad
      #   def seems_to_be_even(value)
      #   end
      #
      #   # When ForbiddenPrefixes: ['seems_to_be_']
      #   # good
      #   def even?(value)
      #   end
      #
      #   # When ForbiddenPrefixes: []
      #   # good
      #   def seems_to_be_even?(value)
      #   end
      #
      # @example AllowedMethods: ['is_a?'] (default)
      #   # Despite starting with the `is_` prefix, this method is allowed
      #   # good
      #   def is_a?(value)
      #   end
      #
      # @example AllowedMethods: ['is_even?']
      #   # good
      #   def is_even?(value)
      #   end
      #
      # @example UseSorbetSigs: false (default)
      #  # bad
      #  sig { returns(String) }
      #  def is_this_thing_on
      #    "yes"
      #  end
      #
      #  # good - Sorbet signature is not evaluated
      #  sig { returns(String) }
      #  def is_this_thing_on?
      #    "yes"
      #  end
      #
      # @example UseSorbetSigs: true
      #   # bad
      #   sig { returns(T::Boolean) }
      #   def odd(value)
      #   end
      #
      #   # good
      #   sig { returns(T::Boolean) }
      #   def odd?(value)
      #   end
      #
      # @example MethodDefinitionMacros: ['define_method', 'define_singleton_method'] (default)
      #   # bad
      #   define_method(:is_even) { |value| }
      #
      #   # good
      #   define_method(:even?) { |value| }
      #
      # @example MethodDefinitionMacros: ['def_node_matcher']
      #   # bad
      #   def_node_matcher(:is_even) { |value| }
      #
      #   # good
      #   def_node_matcher(:even?) { |value| }
      #
      class PredicateName < Base
        include AllowedMethods

        # @!method dynamic_method_define(node)
        def_node_matcher :dynamic_method_define, <<~PATTERN
          (send nil? #method_definition_macros
            (sym $_)
            ...)
        PATTERN

        def on_send(node)
          dynamic_method_define(node) do |method_name|
            predicate_prefixes.each do |prefix|
              next if allowed_method_name?(method_name.to_s, prefix)

              add_offense(
                node.first_argument,
                message: message(method_name, expected_name(method_name.to_s, prefix))
              )
            end
          end
        end

        def on_def(node)
          predicate_prefixes.each do |prefix|
            method_name = node.method_name.to_s

            next if allowed_method_name?(method_name, prefix)
            next if use_sorbet_sigs? && !sorbet_sig?(node, return_type: 'T::Boolean')

            add_offense(
              node.loc.name,
              message: message(method_name, expected_name(method_name, prefix))
            )
          end
        end
        alias on_defs on_def

        def validate_config
          forbidden_prefixes.each do |forbidden_prefix|
            next if predicate_prefixes.include?(forbidden_prefix)

            raise ValidationError, <<~MSG.chomp
              The `Naming/PredicateName` cop is misconfigured. Prefix #{forbidden_prefix} must be included in NamePrefix because it is included in ForbiddenPrefixes.
            MSG
          end
        end

        private

        # @!method sorbet_return_type(node)
        def_node_matcher :sorbet_return_type, <<~PATTERN
          (block (send nil? :sig) args (send _ :returns $_type))
        PATTERN

        def sorbet_sig?(node, return_type: nil)
          return false unless (type = sorbet_return_type(node.left_sibling))

          type.source == return_type
        end

        def allowed_method_name?(method_name, prefix)
          !(method_name.start_with?(prefix) && # cheap check to avoid allocating Regexp
              method_name.match?(/^#{prefix}[^0-9]/)) ||
            method_name == expected_name(method_name, prefix) ||
            method_name.end_with?('=') ||
            allowed_method?(method_name)
        end

        def expected_name(method_name, prefix)
          new_name = if forbidden_prefixes.include?(prefix)
                       method_name.sub(prefix, '')
                     else
                       method_name.dup
                     end
          new_name << '?' unless method_name.end_with?('?')
          new_name
        end

        def message(method_name, new_name)
          "Rename `#{method_name}` to `#{new_name}`."
        end

        def forbidden_prefixes
          cop_config['ForbiddenPrefixes']
        end

        def predicate_prefixes
          cop_config['NamePrefix']
        end

        def use_sorbet_sigs?
          cop_config['UseSorbetSigs']
        end

        def method_definition_macros(macro_name)
          cop_config['MethodDefinitionMacros'].include?(macro_name.to_s)
        end
      end
    end
  end
end
