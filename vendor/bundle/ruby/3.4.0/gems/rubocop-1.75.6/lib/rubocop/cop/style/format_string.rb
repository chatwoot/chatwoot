# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use of a single string formatting utility.
      # Valid options include `Kernel#format`, `Kernel#sprintf`, and `String#%`.
      #
      # The detection of `String#%` cannot be implemented in a reliable
      # manner for all cases, so only two scenarios are considered -
      # if the first argument is a string literal and if the second
      # argument is an array literal.
      #
      # Autocorrection will be applied when using argument is a literal or known built-in conversion
      # methods such as `to_d`, `to_f`, `to_h`, `to_i`, `to_r`, `to_s`, and `to_sym` on variables,
      # provided that their return value is not an array. For example, when using `to_s`,
      # `'%s' % [1, 2, 3].to_s` can be autocorrected without any incompatibility:
      #
      # [source,ruby]
      # ----
      # '%s' % [1, 2, 3]        #=> '1'
      # format('%s', [1, 2, 3]) #=> '[1, 2, 3]'
      # '%s' % [1, 2, 3].to_s   #=> '[1, 2, 3]'
      # ----
      #
      # @example EnforcedStyle: format (default)
      #   # bad
      #   puts sprintf('%10s', 'foo')
      #   puts '%10s' % 'foo'
      #
      #   # good
      #   puts format('%10s', 'foo')
      #
      # @example EnforcedStyle: sprintf
      #   # bad
      #   puts format('%10s', 'foo')
      #   puts '%10s' % 'foo'
      #
      #   # good
      #   puts sprintf('%10s', 'foo')
      #
      # @example EnforcedStyle: percent
      #   # bad
      #   puts format('%10s', 'foo')
      #   puts sprintf('%10s', 'foo')
      #
      #   # good
      #   puts '%10s' % 'foo'
      #
      class FormatString < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Favor `%<prefer>s` over `%<current>s`.'
        RESTRICT_ON_SEND = %i[format sprintf %].freeze

        # Known conversion methods whose return value is not an array.
        AUTOCORRECTABLE_METHODS = %i[to_d to_f to_h to_i to_r to_s to_sym].freeze

        # @!method formatter(node)
        def_node_matcher :formatter, <<~PATTERN
          {
            (send nil? ${:sprintf :format} _ _ ...)
            (send {str dstr} $:% ... )
            (send !nil? $:% {array hash})
          }
        PATTERN

        # @!method variable_argument?(node)
        def_node_matcher :variable_argument?, <<~PATTERN
          (send {str dstr} :% #autocorrectable?)
        PATTERN

        def on_send(node)
          formatter(node) do |selector|
            detected_style = selector == :% ? :percent : selector

            return if detected_style == style

            add_offense(node.loc.selector, message: message(detected_style)) do |corrector|
              autocorrect(corrector, node)
            end
          end
        end

        private

        def autocorrectable?(node)
          return true if node.lvar_type?

          node.send_type? && !AUTOCORRECTABLE_METHODS.include?(node.method_name)
        end

        def message(detected_style)
          format(MSG, prefer: method_name(style), current: method_name(detected_style))
        end

        def method_name(style_name)
          style_name == :percent ? 'String#%' : style_name
        end

        def autocorrect(corrector, node)
          return if variable_argument?(node)

          case node.method_name
          when :%
            autocorrect_from_percent(corrector, node)
          when :format, :sprintf
            case style
            when :percent
              autocorrect_to_percent(corrector, node)
            when :format, :sprintf
              corrector.replace(node.loc.selector, style.to_s)
            end
          end
        end

        def autocorrect_from_percent(corrector, node)
          percent_rhs = node.first_argument
          args = case percent_rhs.type
                 when :array, :hash
                   percent_rhs.children.map(&:source).join(', ')
                 else
                   percent_rhs.source
                 end

          corrected = "#{style}(#{node.receiver.source}, #{args})"

          corrector.replace(node, corrected)
        end

        def autocorrect_to_percent(corrector, node)
          format_arg, *param_args = node.arguments
          format = format_arg.source

          args = if param_args.one?
                   format_single_parameter(param_args.last)
                 else
                   "[#{param_args.map(&:source).join(', ')}]"
                 end

          corrector.replace(node, "#{format} % #{args}")
        end

        def format_single_parameter(arg)
          source = arg.source
          return "{ #{source} }" if arg.hash_type?

          arg.send_type? && arg.operator_method? && !arg.parenthesized? ? "(#{source})" : source
        end
      end
    end
  end
end
