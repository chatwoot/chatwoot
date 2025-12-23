# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for `private` or `protected` access modifiers which are
      # applied to a singleton method. These access modifiers do not make
      # singleton methods private/protected. `private_class_method` can be
      # used for that.
      #
      # @example
      #
      #   # bad
      #   class C
      #     private
      #
      #     def self.method
      #       puts 'hi'
      #     end
      #   end
      #
      #   # good
      #   class C
      #     def self.method
      #       puts 'hi'
      #     end
      #
      #     private_class_method :method
      #   end
      #
      #   # good
      #   class C
      #     class << self
      #       private
      #
      #       def method
      #         puts 'hi'
      #       end
      #     end
      #   end
      class IneffectiveAccessModifier < Base
        MSG = '`%<modifier>s` (on line %<line>d) does not make singleton ' \
              'methods %<modifier>s. Use %<alternative>s instead.'
        ALTERNATIVE_PRIVATE = '`private_class_method` or `private` inside a `class << self` block'
        ALTERNATIVE_PROTECTED = '`protected` inside a `class << self` block'

        # @!method private_class_methods(node)
        def_node_search :private_class_methods, <<~PATTERN
          (send nil? :private_class_method $...)
        PATTERN

        def on_class(node)
          check_node(node.body)
        end
        alias on_module on_class

        private

        def check_node(node)
          return unless node&.begin_type?

          ineffective_modifier(node) do |defs_node, modifier|
            add_offense(defs_node.loc.keyword, message: format_message(modifier))
          end
        end

        def private_class_method_names(node)
          private_class_methods(node).to_a.flatten.select(&:basic_literal?).map(&:value)
        end

        def format_message(modifier)
          visibility = modifier.method_name
          alternative = if visibility == :private
                          ALTERNATIVE_PRIVATE
                        else
                          ALTERNATIVE_PROTECTED
                        end
          format(MSG, modifier: visibility,
                      line: modifier.source_range.line,
                      alternative: alternative)
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def ineffective_modifier(node, ignored_methods = nil, modifier = nil, &block)
          node.each_child_node do |child|
            case child.type
            when :send
              modifier = child if access_modifier?(child)
            when :defs
              ignored_methods ||= private_class_method_names(node)
              next if correct_visibility?(child, modifier, ignored_methods)

              yield child, modifier
            when :kwbegin
              ignored_methods ||= private_class_method_names(node)
              ineffective_modifier(child, ignored_methods, modifier, &block)
            end
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def access_modifier?(node)
          node.bare_access_modifier? && !node.method?(:module_function)
        end

        def correct_visibility?(node, modifier, ignored_methods)
          return true if modifier.nil? || modifier.method?(:public)

          ignored_methods.include?(node.method_name)
        end
      end
    end
  end
end
