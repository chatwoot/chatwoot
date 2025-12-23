# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that `context` docstring starts with an allowed prefix.
      #
      # The default list of prefixes is minimal. Users are encouraged to tailor
      # the configuration to meet project needs. Other acceptable prefixes may
      # include `if`, `unless`, `for`, `before`, `after`, or `during`.
      # They may consist of multiple words if desired.
      #
      # @see http://www.betterspecs.org/#contexts
      #
      # If both `Prefixes` and `AllowedPatterns` are empty, this cop will always
      # report an offense. So you need to set at least one of them.
      #
      # @example `Prefixes` configuration
      #   # .rubocop.yml
      #   # RSpec/ContextWording:
      #   #   Prefixes:
      #   #     - when
      #   #     - with
      #   #     - without
      #   #     - if
      #   #     - unless
      #   #     - for
      #
      # @example
      #   # bad
      #   context 'the display name not present' do
      #     # ...
      #   end
      #
      #   # good
      #   context 'when the display name is not present' do
      #     # ...
      #   end
      #
      # This cop can be customized allowed context description pattern
      # with `AllowedPatterns`. By default, there are no checking by pattern.
      #
      # @example `AllowedPatterns` configuration
      #
      #   # .rubocop.yml
      #   # RSpec/ContextWording:
      #   #   AllowedPatterns:
      #   #     - とき$
      #
      # @example
      #   # bad
      #   context '条件を満たす' do
      #     # ...
      #   end
      #
      #   # good
      #   context '条件を満たすとき' do
      #     # ...
      #   end
      #
      class ContextWording < Base
        include AllowedPattern

        MSG_MATCH = 'Context description should match %<patterns>s.'
        MSG_ALWAYS = 'Current settings will always report an offense. Please ' \
                     'add allowed words to `Prefixes` or `AllowedPatterns`.'

        # @!method context_wording(node)
        def_node_matcher :context_wording, <<~PATTERN
          (block (send #rspec? { :context :shared_context } $({str dstr xstr} ...) ...) ...)
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          context_wording(node) do |context|
            unless matches_allowed_pattern?(description(context))
              add_offense(context, message: message)
            end
          end
        end

        private

        def allowed_patterns
          super + prefix_regexes
        end

        def prefix_regexes
          @prefix_regexes ||= prefixes.map { |pre| /^#{Regexp.escape(pre)}\b/ }
        end

        def description(context)
          if context.xstr_type?
            context.value.value
          else
            context.value
          end
        end

        def message
          if allowed_patterns.empty?
            MSG_ALWAYS
          else
            format(MSG_MATCH, patterns: expect_patterns)
          end
        end

        def expect_patterns
          inspected = allowed_patterns.map do |pattern|
            pattern.inspect.gsub(/\A"|"\z/, '/')
          end
          return inspected.first if inspected.size == 1

          inspected << "or #{inspected.pop}"
          inspected.join(', ')
        end

        def prefixes
          Array(cop_config.fetch('Prefixes', [])).tap do |prefixes|
            non_strings = prefixes.reject { |pre| pre.is_a?(String) }
            unless non_strings.empty?
              raise "Non-string prefixes #{non_strings.inspect} detected."
            end
          end
        end
      end
    end
  end
end
