# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for common mistakes in example descriptions.
      #
      # This cop will correct docstrings that begin with 'should' and 'it'.
      # This cop will also look for insufficient examples and call them out.
      #
      # @see http://betterspecs.org/#should
      #
      # The autocorrect is experimental - use with care! It can be configured
      # with CustomTransform (e.g. have => has) and IgnoredWords (e.g. only).
      #
      # Use the DisallowedExamples setting to prevent unclear or insufficient
      # descriptions. Please note that this config will not be treated as
      # case sensitive.
      #
      # @example
      #   # bad
      #   it 'should find nothing' do
      #   end
      #
      #   it 'will find nothing' do
      #   end
      #
      #   # good
      #   it 'finds nothing' do
      #   end
      #
      # @example
      #   # bad
      #   it 'it does things' do
      #   end
      #
      #   # good
      #   it 'does things' do
      #   end
      #
      # @example `DisallowedExamples: ['works']` (default)
      #   # bad
      #   it 'works' do
      #   end
      #
      #   # good
      #   it 'marks the task as done' do
      #   end
      class ExampleWording < Base
        extend AutoCorrector

        MSG_SHOULD = 'Do not use should when describing your tests.'
        MSG_WILL   = 'Do not use the future tense when describing your tests.'
        MSG_IT     = "Do not repeat 'it' when describing your tests."
        MSG_INSUFFICIENT_DESCRIPTION = 'Your example description is ' \
                                       'insufficient.'

        SHOULD_PREFIX = /\Ashould(?:n't|n’t)?\b/i.freeze
        WILL_PREFIX   = /\A(?:will|won't|won’t)\b/i.freeze
        IT_PREFIX     = /\Ait /i.freeze

        # @!method it_description(node)
        def_node_matcher :it_description, <<~PATTERN
          (block (send _ :it ${
            (str $_)
            (dstr (str $_ ) ...)
          } ...) ...)
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          it_description(node) do |description_node, message|
            if message.match?(SHOULD_PREFIX)
              add_wording_offense(description_node, MSG_SHOULD)
            elsif message.match?(WILL_PREFIX)
              add_wording_offense(description_node, MSG_WILL)
            elsif message.match?(IT_PREFIX)
              add_wording_offense(description_node, MSG_IT)
            elsif insufficient_docstring?(description_node)
              add_offense(docstring(description_node),
                          message: MSG_INSUFFICIENT_DESCRIPTION)
            end
          end
        end

        private

        def add_wording_offense(node, message)
          docstring = docstring(node)

          add_offense(docstring, message: message) do |corrector|
            next if node.heredoc?

            corrector.replace(docstring, replacement_text(node))
          end
        end

        def docstring(node)
          expr = node.source_range

          Parser::Source::Range.new(
            expr.source_buffer,
            expr.begin_pos + 1,
            expr.end_pos - 1
          )
        end

        def replacement_text(node)
          text = text(node)

          if text.match?(SHOULD_PREFIX) || text.match?(WILL_PREFIX)
            RuboCop::RSpec::Wording.new(
              text,
              ignore:  ignored_words,
              replace: custom_transform
            ).rewrite
          else
            text.sub(IT_PREFIX, '')
          end
        end

        # Recursive processing is required to process nested dstr nodes
        # that is the case for \-separated multiline strings with interpolation.
        def text(node)
          case node.type
          when :dstr
            node.node_parts.map { |child_node| text(child_node) }.join
          when :str
            node.value
          else
            node.source
          end
        end

        def custom_transform
          cop_config.fetch('CustomTransform', {})
        end

        def ignored_words
          cop_config.fetch('IgnoredWords', [])
        end

        def insufficient_docstring?(description_node)
          insufficient_examples.include?(preprocess(text(description_node)))
        end

        def insufficient_examples
          examples = cop_config.fetch('DisallowedExamples', [])
          examples.map! { |example| preprocess(example) }
        end

        def preprocess(message)
          message.strip.squeeze(' ').downcase
        end
      end
    end
  end
end
