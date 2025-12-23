# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for the correct use of Date methods,
      # such as Date.today, Date.current etc.
      #
      # Using `Date.today` is dangerous, because it doesn't know anything about
      # Rails time zone. You must use `Time.zone.today` instead.
      #
      # The cop also reports warnings when you are using `to_time` method,
      # because it doesn't know about Rails time zone either.
      #
      # Two styles are supported for this cop. When `EnforcedStyle` is `strict`
      # then the Date methods `today`, `current`, `yesterday`, and `tomorrow`
      # are prohibited and the usage of both `to_time`
      # and `to_time_in_current_zone` are reported as warning.
      #
      # When `EnforcedStyle` is `flexible` then only `Date.today` is prohibited.
      #
      # And you can set a warning for `to_time` with `AllowToTime: false`.
      # `AllowToTime` is `true` by default to prevent false positive on `DateTime` object.
      #
      # @safety
      #   This cop's autocorrection is unsafe because it may change handling time.
      #
      # @example EnforcedStyle: flexible (default)
      #   # bad
      #   Date.today
      #
      #   # good
      #   Time.zone.today
      #   Time.zone.today - 1.day
      #   Date.current
      #   Date.yesterday
      #   date.in_time_zone
      #
      # @example EnforcedStyle: strict
      #   # bad
      #   Date.current
      #   Date.yesterday
      #   Date.today
      #
      #   # good
      #   Time.zone.today
      #   Time.zone.today - 1.day
      #
      # @example AllowToTime: true (default)
      #   # good
      #   date.to_time
      #
      # @example AllowToTime: false
      #   # bad
      #   date.to_time
      class Date < Base
        extend AutoCorrector

        include ConfigurableEnforcedStyle

        MSG = 'Do not use `Date.%<method_called>s` without zone. Use `Time.zone.%<day>s` instead.'

        MSG_SEND = 'Do not use `%<method>s` on Date objects, because they know nothing about the time zone in use.'

        RESTRICT_ON_SEND = %i[to_time to_time_in_current_zone].freeze

        BAD_DAYS = %i[today current yesterday tomorrow].freeze

        DEPRECATED_METHODS = [{ deprecated: 'to_time_in_current_zone', relevant: 'in_time_zone' }].freeze

        DEPRECATED_MSG = '`%<deprecated>s` is deprecated. Use `%<relevant>s` instead.'

        def on_const(node)
          mod, klass = *node.children
          # we should only check core Date class (`Date` or `::Date`)
          return unless (mod.nil? || mod.cbase_type?) && method_send?(node)

          check_date_node(node.parent) if klass == :Date
        end

        def on_send(node)
          return unless node.receiver && bad_methods.include?(node.method_name)
          return if allow_to_time? && node.method?(:to_time)
          return if safe_chain?(node) || safe_to_time?(node)

          check_deprecated_methods(node)

          add_offense(node.loc.selector, message: format(MSG_SEND, method: node.method_name))
        end
        alias on_csend on_send

        private

        def check_deprecated_methods(node)
          DEPRECATED_METHODS.each do |method|
            next unless node.method?(method[:deprecated].to_sym)

            message = format(DEPRECATED_MSG, deprecated: method[:deprecated], relevant: method[:relevant])

            add_offense(node.loc.selector, message: message) do |corrector|
              corrector.replace(node.loc.selector, method[:relevant].to_s)
            end
          end
        end

        def check_date_node(node)
          chain = extract_method_chain(node)

          return if (chain & bad_days).empty?

          method_name = (chain & bad_days).join('.')

          day = method_name
          day = 'today' if method_name == 'current'

          message = format(MSG, method_called: method_name, day: day)

          add_offense(node.loc.selector, message: message) do |corrector|
            corrector.replace(node.receiver.loc.name, 'Time.zone')
          end
        end

        def extract_method_chain(node)
          [node, *node.each_ancestor(:send)].map(&:method_name)
        end

        # checks that parent node of send_type
        # and receiver is the given node
        def method_send?(node)
          return false unless node.parent&.send_type?

          node.parent.receiver == node
        end

        def safe_chain?(node)
          chain = extract_method_chain(node)

          (chain & bad_methods).empty? || !(chain & good_methods).empty?
        end

        def safe_to_time?(node)
          return false unless node.method?(:to_time)

          if node.receiver.str_type?
            zone_regexp = /([+-][\d:]+|\dZ)\z/

            node.receiver.str_content.match(zone_regexp)
          else
            node.arguments.one?
          end
        end

        def allow_to_time?
          cop_config.fetch('AllowToTime', true)
        end

        def good_days
          style == :strict ? [] : %i[current yesterday tomorrow]
        end

        def bad_days
          BAD_DAYS - good_days
        end

        def bad_methods
          %i[to_time to_time_in_current_zone]
        end

        def good_methods
          style == :strict ? [] : TimeZone::ACCEPTED_METHODS
        end
      end
    end
  end
end
