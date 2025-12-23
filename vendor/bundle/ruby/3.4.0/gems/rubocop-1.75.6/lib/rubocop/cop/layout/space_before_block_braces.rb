# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks that block braces have or don't have a space before the opening
      # brace depending on configuration.
      #
      # @example EnforcedStyle: space (default)
      #   # bad
      #   foo.map{ |a|
      #     a.bar.to_s
      #   }
      #
      #   # good
      #   foo.map { |a|
      #     a.bar.to_s
      #   }
      #
      # @example EnforcedStyle: no_space
      #   # bad
      #   foo.map { |a|
      #     a.bar.to_s
      #   }
      #
      #   # good
      #   foo.map{ |a|
      #     a.bar.to_s
      #   }
      #
      # @example EnforcedStyleForEmptyBraces: space (default)
      #   # bad
      #   7.times{}
      #
      #   # good
      #   7.times {}
      #
      # @example EnforcedStyleForEmptyBraces: no_space
      #   # bad
      #   7.times {}
      #
      #   # good
      #   7.times{}
      class SpaceBeforeBlockBraces < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MISSING_MSG = 'Space missing to the left of {.'
        DETECTED_MSG = 'Space detected to the left of {.'

        def self.autocorrect_incompatible_with
          [Style::SymbolProc]
        end

        def on_block(node)
          return if node.keywords?

          # Do not register an offense for multi-line braces when specifying
          # `EnforcedStyle: no_space`. It will conflict with autocorrection
          # by `EnforcedStyle: line_count_based` of `Style/BlockDelimiters` cop.
          # That means preventing autocorrection to incorrect autocorrected
          # code.
          # See: https://github.com/rubocop/rubocop/issues/7534
          return if conflict_with_block_delimiters?(node)

          left_brace = node.loc.begin
          space_plus_brace = range_with_surrounding_space(left_brace)
          used_style =
            space_plus_brace.source.start_with?('{') ? :no_space : :space

          if empty_braces?(node.loc)
            check_empty(left_brace, space_plus_brace, used_style)
          else
            check_non_empty(left_brace, space_plus_brace, used_style)
          end
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        def check_empty(left_brace, space_plus_brace, used_style)
          if style_for_empty_braces == used_style
            handle_different_styles_for_empty_braces(used_style)
            return
          elsif !config_to_allow_offenses.key?('Enabled')
            config_to_allow_offenses['EnforcedStyleForEmptyBraces'] = used_style.to_s
          end

          if style_for_empty_braces == :space
            range = left_brace
            msg = MISSING_MSG
          else
            range = range_between(space_plus_brace.begin_pos, left_brace.begin_pos)
            msg = DETECTED_MSG
          end
          add_offense(range, message: msg) { |corrector| autocorrect(corrector, range) }
        end

        def handle_different_styles_for_empty_braces(used_style)
          if config_to_allow_offenses['EnforcedStyleForEmptyBraces'] &&
             config_to_allow_offenses['EnforcedStyleForEmptyBraces'].to_sym != used_style
            config_to_allow_offenses.clear
            config_to_allow_offenses['Enabled'] = false
          end
        end

        def check_non_empty(left_brace, space_plus_brace, used_style)
          case used_style
          when style  then correct_style_detected
          when :space then space_detected(left_brace, space_plus_brace)
          else             space_missing(left_brace)
          end
        end

        def space_missing(left_brace)
          add_offense(left_brace, message: MISSING_MSG) do |corrector|
            autocorrect(corrector, left_brace)
            opposite_style_detected
          end
        end

        def space_detected(left_brace, space_plus_brace)
          space = range_between(space_plus_brace.begin_pos, left_brace.begin_pos)

          add_offense(space, message: DETECTED_MSG) do |corrector|
            autocorrect(corrector, space)
            opposite_style_detected
          end
        end

        def autocorrect(corrector, range)
          case range.source
          when /\s/ then corrector.remove(range)
          else           corrector.insert_before(range, ' ')
          end
        end

        def style_for_empty_braces
          case cop_config['EnforcedStyleForEmptyBraces']
          when 'space'    then :space
          when 'no_space' then :no_space
          when nil then style
          else raise 'Unknown EnforcedStyleForEmptyBraces selected!'
          end
        end

        def conflict_with_block_delimiters?(node)
          block_delimiters_style == 'line_count_based' && style == :no_space && node.multiline?
        end

        def block_delimiters_style
          config.for_cop('Style/BlockDelimiters')['EnforcedStyle']
        end

        def empty_braces?(loc)
          loc.begin.end_pos == loc.end.begin_pos
        end
      end
    end
  end
end
