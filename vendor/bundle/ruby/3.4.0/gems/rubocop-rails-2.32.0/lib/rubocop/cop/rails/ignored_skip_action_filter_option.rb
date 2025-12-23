# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks that `if` and `only` (or `except`) are not used together
      # as options of `skip_*` action filter.
      #
      # The `if` option will be ignored when `if` and `only` are used together.
      # Similarly, the `except` option will be ignored when `if` and `except`
      # are used together.
      #
      # @example
      #   # bad
      #   class MyPageController < ApplicationController
      #     skip_before_action :login_required,
      #       only: :show, if: :trusted_origin?
      #   end
      #
      #   # good
      #   class MyPageController < ApplicationController
      #     skip_before_action :login_required,
      #       if: -> { trusted_origin? && action_name == "show" }
      #   end
      #
      # @example
      #   # bad
      #   class MyPageController < ApplicationController
      #     skip_before_action :login_required,
      #       except: :admin, if: :trusted_origin?
      #   end
      #
      #   # good
      #   class MyPageController < ApplicationController
      #     skip_before_action :login_required,
      #       if: -> { trusted_origin? && action_name != "admin" }
      #   end
      class IgnoredSkipActionFilterOption < Base
        extend AutoCorrector

        include RangeHelp

        MSG = <<~MSG.chomp.freeze
          `%<ignore>s` option will be ignored when `%<prefer>s` and `%<ignore>s` are used together.
        MSG

        RESTRICT_ON_SEND = %i[skip_after_action skip_around_action skip_before_action skip_action_callback].freeze

        FILTERS = RESTRICT_ON_SEND.map { |method_name| ":#{method_name}" }

        def_node_matcher :filter_options, <<~PATTERN
          (send
            nil?
            {#{FILTERS.join(' ')}}
            ...
            $_)
        PATTERN

        def on_send(node)
          options = filter_options(node)
          return unless options
          return unless options.hash_type?

          options = options_hash(options)

          if if_and_only?(options)
            add_offense(options[:if], message: format(MSG, prefer: :only, ignore: :if)) do |corrector|
              remove_node_with_left_space_and_comma(corrector, options[:if])
            end
          elsif if_and_except?(options)
            add_offense(options[:except], message: format(MSG, prefer: :if, ignore: :except)) do |corrector|
              remove_node_with_left_space_and_comma(corrector, options[:except])
            end
          end
        end

        private

        def options_hash(options)
          options.pairs
                 .select { |pair| pair.key.sym_type? }
                 .to_h { |pair| [pair.key.value, pair] }
        end

        def if_and_only?(options)
          options.key?(:if) && options.key?(:only)
        end

        def if_and_except?(options)
          options.key?(:if) && options.key?(:except)
        end

        def remove_node_with_left_space_and_comma(corrector, node)
          corrector.remove(
            range_with_surrounding_comma(
              range_with_surrounding_space(
                node.source_range,
                side: :left
              ),
              :left
            )
          )
        end
      end
    end
  end
end
