# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for single-line method definitions that contain a body.
      # It will accept single-line methods with no body.
      #
      # Endless methods added in Ruby 3.0 are also accepted by this cop.
      #
      # If `Style/EndlessMethod` is enabled with `EnforcedStyle: allow_single_line`, `allow_always`,
      # `require_single_line`, or `require_always`, single-line methods will be autocorrected
      # to endless methods if there is only one statement in the body.
      #
      # @example
      #   # bad
      #   def some_method; body end
      #   def link_to(url); {:name => url}; end
      #   def @table.columns; super; end
      #
      #   # good
      #   def self.resource_class=(klass); end
      #   def @table.columns; end
      #   def some_method() = body
      #
      # @example AllowIfMethodIsEmpty: true (default)
      #   # good
      #   def no_op; end
      #
      # @example AllowIfMethodIsEmpty: false
      #   # bad
      #   def no_op; end
      #
      class SingleLineMethods < Base
        include Alignment
        extend AutoCorrector

        MSG = 'Avoid single-line method definitions.'
        NOT_SUPPORTED_ENDLESS_METHOD_BODY_TYPES = %i[return break next].freeze

        def on_def(node)
          return unless node.single_line?
          return if node.endless?
          return if allow_empty? && !node.body

          add_offense(node) { |corrector| autocorrect(corrector, node) }
        end
        alias on_defs on_def

        private

        def autocorrect(corrector, node)
          if correct_to_endless?(node.body)
            correct_to_endless(corrector, node)
          else
            correct_to_multiline(corrector, node)
          end
        end

        def allow_empty?
          cop_config['AllowIfMethodIsEmpty']
        end

        def correct_to_endless?(body_node)
          return false if target_ruby_version < 3.0
          return false if disallow_endless_method_style?
          return false unless body_node
          return false if body_node.parent.assignment_method? ||
                          NOT_SUPPORTED_ENDLESS_METHOD_BODY_TYPES.include?(body_node.type)

          !body_node.type?(:begin, :kwbegin)
        end

        def correct_to_multiline(corrector, node)
          if (body = node.body) && body.begin_type? && body.parenthesized_call?
            break_line_before(corrector, node, body)
          else
            each_part(body) do |part|
              break_line_before(corrector, node, part)
            end
          end

          break_line_before(corrector, node, node.loc.end, indent_steps: 0)

          move_comment(node, corrector)
        end

        def correct_to_endless(corrector, node)
          self_receiver = node.self_receiver? ? 'self.' : ''
          arguments = node.arguments.any? ? node.arguments.source : '()'
          body_source = method_body_source(node.body)
          replacement = "def #{self_receiver}#{node.method_name}#{arguments} = #{body_source}"

          corrector.replace(node, replacement)
        end

        def break_line_before(corrector, node, range, indent_steps: 1)
          LineBreakCorrector.break_line_before(
            range: range, node: node, corrector: corrector,
            configured_width: configured_indentation_width, indent_steps: indent_steps
          )
        end

        def each_part(body)
          return unless body

          if body.begin_type?
            body.each_child_node { |part| yield part.source_range }
          else
            yield body.source_range
          end
        end

        def move_comment(node, corrector)
          LineBreakCorrector.move_comment(
            eol_comment: processed_source.comment_at_line(node.source_range.line),
            node: node, corrector: corrector
          )
        end

        def method_body_source(method_body)
          if require_parentheses?(method_body)
            arguments_source = method_body.arguments.map(&:source).join(', ')
            body_source = "#{method_body.method_name}(#{arguments_source})"

            method_body.receiver ? "#{method_body.receiver.source}.#{body_source}" : body_source
          else
            method_body.source
          end
        end

        def require_parentheses?(method_body)
          method_body.send_type? && !method_body.arguments.empty? && !method_body.comparison_method?
        end

        def disallow_endless_method_style?
          return true unless config.cop_enabled?('Style/EndlessMethod')

          config.for_cop('Style/EndlessMethod')['EnforcedStyle'] == 'disallow'
        end
      end
    end
  end
end
