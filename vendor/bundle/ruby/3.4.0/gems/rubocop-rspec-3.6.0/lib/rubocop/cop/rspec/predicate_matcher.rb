# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # A helper for `inflected` style
      module InflectedHelper
        include RuboCop::RSpec::Language
        extend NodePattern::Macros

        MSG_INFLECTED = 'Prefer using `%<matcher_name>s` matcher over ' \
                        '`%<predicate_name>s`.'

        private

        def check_inflected(node)
          predicate_in_actual?(node) do |predicate, to, matcher|
            next if cannot_replace_predicate?(predicate)

            msg = message_inflected(predicate)
            add_offense(node, message: msg) do |corrector|
              remove_predicate(corrector, predicate)
              corrector.replace(node.loc.selector,
                                true?(to, matcher) ? 'to' : 'not_to')
              rewrite_matcher(corrector, predicate, matcher)
            end
          end
        end

        # @!method predicate_in_actual?(node)
        def_node_matcher :predicate_in_actual?, <<~PATTERN
          (send
            (send nil? :expect {
              (block $(send !nil? #predicate? ...) ...)
              $(send !nil? #predicate? ...)})
            $#Runners.all
            $#boolean_matcher? ...)
        PATTERN

        def cannot_replace_predicate?(send_node)
          send_node.method?(:respond_to?) && send_node.arguments.length > 1
        end

        # @!method be_bool?(node)
        def_node_matcher :be_bool?, <<~PATTERN
          (send nil? {:be :eq :eql :equal} boolean)
        PATTERN

        # @!method be_boolthy?(node)
        def_node_matcher :be_boolthy?, <<~PATTERN
          (send nil? {:be_truthy :be_falsey :be_falsy :a_truthy_value :a_falsey_value :a_falsy_value})
        PATTERN

        def boolean_matcher?(node)
          if cop_config['Strict']
            be_boolthy?(node)
          else
            be_bool?(node) || be_boolthy?(node)
          end
        end

        def predicate?(sym)
          sym.to_s.end_with?('?')
        end

        def message_inflected(predicate)
          format(MSG_INFLECTED,
                 predicate_name: predicate.method_name,
                 matcher_name: to_predicate_matcher(predicate.method_name))
        end

        def to_predicate_matcher(name)
          case name = name.to_s
          when 'is_a?'
            'be_a'
          when 'instance_of?'
            'be_an_instance_of'
          when 'include?', 'respond_to?'
            name[0..-2]
          when 'exist?', 'exists?'
            'exist'
          when /\Ahas_/
            name.sub('has_', 'have_')[0..-2]
          else
            "be_#{name[0..-2]}"
          end
        end

        def remove_predicate(corrector, predicate)
          range = predicate.loc.dot.with(
            end_pos: predicate.source_range.end_pos
          )

          corrector.remove(range)

          block_range = LocationHelp.block_with_whitespace(predicate)
          corrector.remove(block_range) if block_range
        end

        def rewrite_matcher(corrector, predicate, matcher)
          args = LocationHelp.arguments_with_whitespace(predicate).source
          block_loc = LocationHelp.block_with_whitespace(predicate)
          block = block_loc ? block_loc.source : ''

          corrector.replace(
            matcher,
            to_predicate_matcher(predicate.method_name) + args + block
          )
        end

        def true?(to_symbol, matcher)
          result = case matcher.method_name
                   when :be, :eq, :eql, :equal
                     matcher.first_argument.true_type?
                   when :be_truthy, :a_truthy_value
                     true
                   when :be_falsey, :be_falsy, :a_falsey_value, :a_falsy_value
                     false
                   else
                     # :nocov:
                     :noop
                     # :nocov:
                   end
          to_symbol == :to ? result : !result
        end
      end

      # A helper for `explicit` style
      module ExplicitHelper # rubocop:disable Metrics/ModuleLength
        include RuboCop::RSpec::Language
        extend NodePattern::Macros

        MSG_EXPLICIT = 'Prefer using `%<predicate_name>s` over ' \
                       '`%<matcher_name>s` matcher.'
        BUILT_IN_MATCHERS = %w[
          be_truthy be_falsey be_falsy
          have_attributes have_received
          be_between be_within
        ].freeze

        private

        def allowed_explicit_matchers
          cop_config.fetch('AllowedExplicitMatchers', []) + BUILT_IN_MATCHERS
        end

        def check_explicit(node) # rubocop:disable Metrics/MethodLength
          predicate_matcher_block?(node) do |actual, matcher|
            add_offense(node, message: message_explicit(matcher)) do |corrector|
              to_node = node.send_node
              corrector_explicit(corrector, to_node, actual, matcher, to_node)
            end
            ignore_node(node.children.first)
            return
          end

          return if part_of_ignored_node?(node)

          predicate_matcher?(node) do |actual, matcher|
            next unless replaceable_matcher?(matcher)

            add_offense(node, message: message_explicit(matcher)) do |corrector|
              next if uncorrectable_matcher?(node, matcher)

              corrector_explicit(corrector, node, actual, matcher, matcher)
            end
          end
        end

        def replaceable_matcher?(matcher)
          case matcher.method_name.to_s
          when 'include'
            matcher.arguments.one?
          else
            true
          end
        end

        def uncorrectable_matcher?(node, matcher)
          heredoc_argument?(matcher) && !same_line?(node, matcher)
        end

        def heredoc_argument?(matcher)
          matcher.arguments.select do |arg|
            arg.type?(:str, :dstr, :xstr)
          end.any?(&:heredoc?)
        end

        # @!method predicate_matcher?(node)
        def_node_matcher :predicate_matcher?, <<~PATTERN
          (send
            (send nil? :expect $!nil?)
            #Runners.all
            {
              $(send nil? #predicate_matcher_name? ...)
              (block $(send nil? #predicate_matcher_name? ...) ...)
            }
            ...
          )
        PATTERN

        # @!method predicate_matcher_block?(node)
        def_node_matcher :predicate_matcher_block?, <<~PATTERN
          (block
            (send
              (send nil? :expect $!nil?)
              #Runners.all
              $(send nil? #predicate_matcher_name?))
            ...)
        PATTERN

        def predicate_matcher_name?(name)
          name = name.to_s

          return false if allowed_explicit_matchers.include?(name)

          (name.start_with?('be_', 'have_') && !name.end_with?('?')) ||
            %w[include respond_to].include?(name)
        end

        def message_explicit(matcher)
          format(MSG_EXPLICIT,
                 predicate_name: to_predicate_method(matcher.method_name),
                 matcher_name: matcher.method_name)
        end

        def corrector_explicit(corrector, to_node, actual, matcher, block_child)
          replacement_matcher = replacement_matcher(to_node)
          corrector.replace(matcher, replacement_matcher)
          move_predicate(corrector, actual, matcher, block_child)
          corrector.replace(to_node.loc.selector, 'to')
        end

        def move_predicate(corrector, actual, matcher, block_child)
          predicate = to_predicate_method(matcher.method_name)
          args = LocationHelp.arguments_with_whitespace(matcher).source
          block_loc = LocationHelp.block_with_whitespace(block_child)
          block = block_loc ? block_loc.source : ''

          corrector.remove(block_loc) if block_loc
          corrector.insert_after(actual, ".#{predicate}" + args + block)
        end

        def to_predicate_method(matcher)
          case matcher = matcher.to_s
          when 'be_a', 'be_an', 'be_a_kind_of', 'a_kind_of', 'be_kind_of'
            'is_a?'
          when 'be_an_instance_of', 'be_instance_of', 'an_instance_of'
            'instance_of?'
          when 'include'
            'include?'
          when 'respond_to'
            'respond_to?'
          when /\Ahave_(.+)/
            "has_#{Regexp.last_match(1)}?"
          else
            "#{matcher[/\Abe_(.+)/, 1]}?"
          end
        end

        def replacement_matcher(node)
          case [cop_config['Strict'], node.method?(:to)]
          when [true, true]
            'be(true)'
          when [true, false]
            'be(false)'
          when [false, true]
            'be_truthy'
          else
            'be_falsey'
          end
        end
      end

      # Prefer using predicate matcher over using predicate method directly.
      #
      # RSpec defines magic matchers for predicate methods.
      # This cop recommends to use the predicate matcher instead of using
      # predicate method directly.
      #
      # @example Strict: true, EnforcedStyle: inflected (default)
      #   # bad
      #   expect(foo.something?).to be_truthy
      #
      #   # good
      #   expect(foo).to be_something
      #
      #   # also good - It checks "true" strictly.
      #   expect(foo.something?).to be(true)
      #
      # @example Strict: false, EnforcedStyle: inflected
      #   # bad
      #   expect(foo.something?).to be_truthy
      #   expect(foo.something?).to be(true)
      #
      #   # good
      #   expect(foo).to be_something
      #
      # @example Strict: true, EnforcedStyle: explicit
      #   # bad
      #   expect(foo).to be_something
      #
      #   # good - the above code is rewritten to it by this cop
      #   expect(foo.something?).to be(true)
      #
      #   # bad - no autocorrect
      #   expect(foo)
      #     .to be_something(<<~TEXT)
      #       bar
      #     TEXT
      #
      #   # good
      #   expect(foo.something?(<<~TEXT)).to be(true)
      #     bar
      #   TEXT
      #
      # @example Strict: false, EnforcedStyle: explicit
      #   # bad
      #   expect(foo).to be_something
      #
      #   # good - the above code is rewritten to it by this cop
      #   expect(foo.something?).to be_truthy
      #
      class PredicateMatcher < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle
        include InflectedHelper
        include ExplicitHelper

        RESTRICT_ON_SEND = Runners.all

        def on_send(node)
          case style
          when :inflected
            check_inflected(node)
          when :explicit
            check_explicit(node)
          else
            # :nocov:
            :noop
            # :nocov:
          end
        end

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          check_explicit(node) if style == :explicit
        end
      end
    end
  end
end
