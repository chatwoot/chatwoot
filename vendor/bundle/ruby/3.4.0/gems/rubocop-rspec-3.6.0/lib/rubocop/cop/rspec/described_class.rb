# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that tests use `described_class`.
      #
      # If the first argument of describe is a class, the class is exposed to
      # each example via described_class.
      #
      # This cop can be configured using the `EnforcedStyle`, `SkipBlocks`
      # and `OnlyStaticConstants` options.
      # `OnlyStaticConstants` is only relevant when `EnforcedStyle` is
      # `described_class`.
      #
      # @example `EnforcedStyle: described_class` (default)
      #   # bad
      #   describe MyClass do
      #     subject { MyClass.do_something }
      #   end
      #
      #   # good
      #   describe MyClass do
      #     subject { described_class.do_something }
      #   end
      #
      # @example `OnlyStaticConstants: true` (default)
      #   # good
      #   describe MyClass do
      #     subject { MyClass::CONSTANT }
      #   end
      #
      # @example `OnlyStaticConstants: false`
      #   # bad
      #   describe MyClass do
      #     subject { MyClass::CONSTANT }
      #   end
      #
      # @example `EnforcedStyle: explicit`
      #   # bad
      #   describe MyClass do
      #     subject { described_class.do_something }
      #   end
      #
      #   # good
      #   describe MyClass do
      #     subject { MyClass.do_something }
      #   end
      #
      # There's a known caveat with rspec-rails's `controller` helper that
      # runs its block in a different context, and `described_class` is not
      # available to it. `SkipBlocks` option excludes detection in all
      # non-RSpec related blocks.
      #
      # To narrow down this setting to only a specific directory, it is
      # possible to use an overriding configuration file local to that
      # directory.
      #
      # @example `SkipBlocks: true`
      #   # spec/controllers/.rubocop.yml
      #   # RSpec/DescribedClass:
      #   #   SkipBlocks: true
      #
      #   # acceptable
      #   describe MyConcern do
      #     controller(ApplicationController) do
      #       include MyConcern
      #     end
      #   end
      #
      class DescribedClass < Base # rubocop:disable Metrics/ClassLength
        extend AutoCorrector
        include ConfigurableEnforcedStyle
        include Namespace

        DESCRIBED_CLASS = 'described_class'
        MSG             = 'Use `%<replacement>s` instead of `%<src>s`.'

        # @!method common_instance_exec_closure?(node)
        def_node_matcher :common_instance_exec_closure?, <<~PATTERN
          (block (send (const nil? {:Class :Module :Struct}) :new ...) ...)
        PATTERN

        # @!method rspec_block?(node)
        def_node_matcher :rspec_block?,
                         '(any_block (send #rspec? #ALL.all ...) ...)'

        # @!method scope_changing_syntax?(node)
        def_node_matcher :scope_changing_syntax?, '{def class module}'

        # @!method described_constant(node)
        def_node_matcher :described_constant, <<~PATTERN
          (block (send _ :describe $(const ...) ...) (args) $_)
        PATTERN

        # @!method contains_described_class?(node)
        def_node_search :contains_described_class?,
                        '(send nil? :described_class)'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          # In case the explicit style is used, we need to remember what's
          # being described.
          @described_class, body = described_constant(node)

          return unless body

          find_usage(body) do |match|
            msg = message(match.const_name)
            add_offense(match, message: msg) do |corrector|
              autocorrect(corrector, match)
            end
          end
        end

        private

        def autocorrect(corrector, match)
          replacement = if style == :described_class
                          DESCRIBED_CLASS
                        else
                          @described_class.const_name
                        end

          corrector.replace(match, replacement)
        end

        def find_usage(node, &block)
          yield(node) if offensive?(node)
          return if scope_change?(node) || allowed?(node)

          node.each_child_node do |child|
            find_usage(child, &block)
          end
        end

        def allowed?(node)
          node.const_type? && only_static_constants?
        end

        def message(offense)
          if style == :described_class
            format(MSG, replacement: DESCRIBED_CLASS, src: offense)
          else
            format(MSG, replacement: @described_class.const_name,
                        src: DESCRIBED_CLASS)
          end
        end

        def scope_change?(node)
          scope_changing_syntax?(node) ||
            common_instance_exec_closure?(node) ||
            skippable_block?(node)
        end

        def skippable_block?(node)
          return false unless cop_config['SkipBlocks']

          node.any_block_type? && !rspec_block?(node)
        end

        def only_static_constants?
          cop_config.fetch('OnlyStaticConstants', true)
        end

        def offensive?(node)
          if style == :described_class
            offensive_described_class?(node)
          else
            node.send_type? && node.method?(:described_class)
          end
        end

        def offensive_described_class?(node)
          return false unless node.const_type?

          # E.g. `described_class::CONSTANT`
          return false if contains_described_class?(node)

          nearest_described_class, = node.each_ancestor(:block)
            .map { |ancestor| described_constant(ancestor) }.find(&:itself)

          return false if nearest_described_class.equal?(node)

          full_const_name(nearest_described_class) == full_const_name(node)
        end

        def full_const_name(node)
          symbolized_namespace = namespace(node).map(&:to_sym)
          collapse_namespace(symbolized_namespace, const_name(node))
        end

        # @param namespace [Array<Symbol>]
        # @param const [Array<Symbol>]
        # @return [Array<Symbol>]
        # @example
        #   # nil represents base constant
        #   collapse_namespace([], [:C])                # => [:C]
        #   collapse_namespace([:A, :B], [:C])          # => [:A, :B, :C]
        #   collapse_namespace([:A, :B], [:B, :C])      # => [:A, :B, :C]
        #   collapse_namespace([:A, :B], [nil, :C])     # => [nil, :C]
        #   collapse_namespace([:A, :B], [nil, :B, :C]) # => [nil, :B, :C]
        def collapse_namespace(namespace, const)
          return const if namespace.empty? || const.first.nil?

          start = [0, (namespace.length - const.length)].max
          max = namespace.length
          intersection = (start..max).find do |shift|
            namespace[shift, max - shift] == const[0, max - shift]
          end
          [*namespace[0, intersection], *const]
        end

        # @param node [RuboCop::AST::Node]
        # @return [Array<Symbol>]
        # @example
        #   const_name(s(:const, nil, :C))                # => [:C]
        #   const_name(s(:const, s(:const, nil, :M), :C)) # => [:M, :C]
        #   const_name(s(:const, s(:cbase), :C))          # => [nil, :C]
        def const_name(node)
          namespace = node.namespace
          name = node.short_name
          if !namespace
            [name]
          elsif namespace.const_type?
            [*const_name(namespace), name]
          elsif %i[lvar cbase send].include?(namespace.type)
            [nil, name]
          end
        end
      end
    end
  end
end
