# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for places where I18n "lazy" lookup can be used.
      #
      # This cop has two different enforcement modes. When the EnforcedStyle
      # is `lazy` (the default), explicit lookups are added as offenses.
      #
      # When the EnforcedStyle is `explicit` then lazy lookups are added as
      # offenses.
      #
      # @example EnforcedStyle: lazy (default)
      #   # en.yml
      #   # en:
      #   #   books:
      #   #     create:
      #   #       success: Book created!
      #
      #   # bad
      #   class BooksController < ApplicationController
      #     def create
      #       # ...
      #       redirect_to books_url, notice: t('books.create.success')
      #     end
      #   end
      #
      #   # good
      #   class BooksController < ApplicationController
      #     def create
      #       # ...
      #       redirect_to books_url, notice: t('.success')
      #     end
      #   end
      #
      # @example EnforcedStyle: explicit
      #   # bad
      #   class BooksController < ApplicationController
      #     def create
      #       # ...
      #       redirect_to books_url, notice: t('.success')
      #     end
      #   end
      #
      #   # good
      #   class BooksController < ApplicationController
      #     def create
      #       # ...
      #       redirect_to books_url, notice: t('books.create.success')
      #     end
      #   end
      #
      class I18nLazyLookup < Base
        include ConfigurableEnforcedStyle
        include VisibilityHelp
        extend AutoCorrector

        MSG = 'Use %<style>s lookup for the text used in controllers.'

        RESTRICT_ON_SEND = %i[translate t].freeze

        def_node_matcher :translate_call?, <<~PATTERN
          (send nil? {:translate :t} ${sym_type? str_type?} ...)
        PATTERN

        def on_send(node)
          translate_call?(node) do |key_node|
            case style
            when :lazy
              handle_lazy_style(node, key_node)
            when :explicit
              handle_explicit_style(node, key_node)
            end
          end
        end

        private

        def handle_lazy_style(node, key_node)
          key = key_node.value
          return if key.to_s.start_with?('.')

          controller, action = controller_and_action(node)
          return unless controller && action

          scoped_key = get_scoped_key(key_node, controller, action)
          return unless key == scoped_key

          add_offense(key_node) do |corrector|
            unscoped_key = key_node.value.to_s.split('.').last
            corrector.replace(key_node, "'.#{unscoped_key}'")
          end
        end

        def handle_explicit_style(node, key_node)
          key = key_node.value
          return unless key.to_s.start_with?('.')

          controller, action = controller_and_action(node)
          return unless controller && action

          scoped_key = get_scoped_key(key_node, controller, action)
          add_offense(key_node) do |corrector|
            corrector.replace(key_node, "'#{scoped_key}'")
          end
        end

        def controller_and_action(node)
          action_node = node.each_ancestor(:def).first
          return unless action_node && node_visibility(action_node) == :public

          controller_node = node.each_ancestor(:class).first
          return unless controller_node && controller_node.identifier.source.end_with?('Controller')

          [controller_node, action_node]
        end

        def get_scoped_key(key_node, controller, action)
          path = controller_path(controller).tr('/', '.')
          action_name = action.method_name
          key = key_node.value.to_s.split('.').last

          "#{path}.#{action_name}.#{key}"
        end

        def controller_path(controller)
          module_name = controller.parent_module_name
          controller_name = controller.identifier.source

          path = if module_name == 'Object'
                   controller_name
                 else
                   "#{module_name}::#{controller_name}"
                 end

          path.delete_suffix('Controller').underscore
        end

        def message(_range)
          format(MSG, style: style)
        end
      end
    end
  end
end
