# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for the use of Time methods without zone.
      #
      # Built on top of Ruby on Rails style guide (https://rails.rubystyle.guide#time)
      # and the article http://danilenko.org/2012/7/6/rails_timezones/
      #
      # Two styles are supported for this cop. When `EnforcedStyle` is 'strict'
      # then only use of `Time.zone` is allowed.
      #
      # When EnforcedStyle is 'flexible' then it's also allowed
      # to use `Time#in_time_zone`.
      #
      # @safety
      #   This cop's autocorrection is unsafe because it may change handling time.
      #
      # @example
      #   # bad
      #   Time.now
      #   Time.parse('2015-03-02T19:05:37')
      #   '2015-03-02T19:05:37'.to_time
      #
      #   # good
      #   Time.current
      #   Time.zone.now
      #   Time.zone.parse('2015-03-02T19:05:37')
      #   Time.zone.parse('2015-03-02T19:05:37Z') # Respect ISO 8601 format with timezone specifier.
      #   Time.parse('2015-03-02T19:05:37Z') # Also respects ISO 8601
      #   '2015-03-02T19:05:37Z'.to_time # Also respects ISO 8601
      #
      # @example EnforcedStyle: flexible (default)
      #   # `flexible` allows usage of `in_time_zone` instead of `zone`.
      #
      #   # good
      #   Time.at(timestamp).in_time_zone
      #
      # @example EnforcedStyle: strict
      #   # `strict` means that `Time` should be used with `zone`.
      #
      #   # bad
      #   Time.at(timestamp).in_time_zone
      class TimeZone < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Do not use `%<current>s` without zone. Use `%<prefer>s` instead.'
        MSG_ACCEPTABLE = 'Do not use `%<current>s` without zone. Use one of %<prefer>s instead.'
        MSG_LOCALTIME = 'Do not use `Time.localtime` without offset or zone.'
        MSG_STRING_TO_TIME = 'Do not use `String#to_time` without zone. Use `Time.zone.parse` instead.'

        GOOD_METHODS = %i[zone zone_default find_zone find_zone!].freeze
        DANGEROUS_METHODS = %i[now local new parse at].freeze
        ACCEPTED_METHODS = %i[in_time_zone utc getlocal xmlschema iso8601 jisx0301 rfc3339 httpdate to_i to_f].freeze
        TIMEZONE_SPECIFIER = /([A-Za-z]|[+-]\d{2}:?\d{2})\z/.freeze

        RESTRICT_ON_SEND = %i[to_time].freeze

        def on_const(node)
          mod, klass = *node
          # we should only check core classes
          # (`Time` or `::Time`)
          return unless (mod.nil? || mod.cbase_type?) && method_send?(node)

          check_time_node(klass, node.parent) if klass == :Time
        end

        def on_send(node)
          return if !node.receiver&.str_type? || !node.method?(:to_time)
          return if attach_timezone_specifier?(node.receiver)

          add_offense(node.loc.selector, message: MSG_STRING_TO_TIME) do |corrector|
            corrector.replace(node, "Time.zone.parse(#{node.receiver.source})") unless node.csend_type?
          end
        end
        alias on_csend on_send

        private

        def autocorrect(corrector, node)
          # add `.zone`: `Time.at` => `Time.zone.at`
          corrector.insert_after(node.children[0], '.zone')

          case node.method_name
          when :current
            # replace `Time.zone.current` => `Time.zone.now`
            corrector.replace(node.loc.selector, 'now')
          when :new
            autocorrect_time_new(node, corrector)
          end

          # prefer `Time` over `DateTime` class
          corrector.replace(node.children.first, 'Time') if strict?
          remove_redundant_in_time_zone(corrector, node)
        end

        def autocorrect_time_new(node, corrector)
          replacement = replacement(node)

          corrector.replace(node.loc.selector, replacement)
        end

        # remove redundant `.in_time_zone` from `Time.zone.now.in_time_zone`
        def remove_redundant_in_time_zone(corrector, node)
          time_methods_called = extract_method_chain(node)
          return unless time_methods_called.include?(:in_time_zone) || time_methods_called.include?(:zone)

          while node&.send_type?
            if node.children.last == :in_time_zone
              in_time_zone_with_dot = node.loc.selector.adjust(begin_pos: -1)
              corrector.remove(in_time_zone_with_dot)
            end
            node = node.parent
          end
        end

        def check_time_node(klass, node)
          return if attach_timezone_specifier?(node.first_argument)

          chain = extract_method_chain(node)
          return if not_danger_chain?(chain)
          return check_localtime(node) if need_check_localtime?(chain)

          method_name = (chain & DANGEROUS_METHODS).join('.')

          return if offset_provided?(node)

          message = build_message(klass, method_name, node)

          add_offense(node.loc.selector, message: message) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def attach_timezone_specifier?(date)
          return false unless date.respond_to?(:value)

          !date.value.to_s.valid_encoding? || TIMEZONE_SPECIFIER.match?(date.value.to_s)
        end

        def build_message(klass, method_name, node)
          if flexible?
            format(
              MSG_ACCEPTABLE,
              current: "#{klass}.#{method_name}",
              prefer: acceptable_methods(klass, method_name, node).join(', ')
            )
          else
            safe_method_name = safe_method(method_name, node)
            format(MSG, current: "#{klass}.#{method_name}", prefer: "Time.zone.#{safe_method_name}")
          end
        end

        def extract_method_chain(node)
          chain = []
          while !node.nil? && node.send_type?
            chain << node.method_name if method_from_time_class?(node)
            node = node.parent
          end
          chain
        end

        # Only add the method to the chain if the method being
        # called is part of the time class.
        def method_from_time_class?(node)
          receiver, method_name, *_args = *node
          if (receiver.is_a? RuboCop::AST::Node) && !receiver.cbase_type?
            method_from_time_class?(receiver)
          else
            method_name == :Time
          end
        end

        # checks that parent node of send_type
        # and receiver is the given node
        def method_send?(node)
          return false unless node.parent&.send_type?

          node.parent.receiver == node
        end

        def safe_method(method_name, node)
          if %w[new current].include?(method_name)
            replacement(node)
          else
            method_name
          end
        end

        def check_localtime(node)
          selector_node = node

          while node&.send_type?
            break if node.method?(:localtime)

            node = node.parent
          end

          return if node.arguments?

          add_offense(selector_node.loc.selector, message: MSG_LOCALTIME) do |corrector|
            autocorrect(corrector, selector_node)
          end
        end

        def not_danger_chain?(chain)
          (chain & DANGEROUS_METHODS).empty? || !(chain & good_methods).empty?
        end

        def need_check_localtime?(chain)
          flexible? && chain.include?(:localtime)
        end

        def flexible?
          style == :flexible
        end

        def strict?
          style == :strict
        end

        def good_methods
          if strict?
            GOOD_METHODS
          else
            GOOD_METHODS + [:current] + ACCEPTED_METHODS
          end
        end

        def acceptable_methods(klass, method_name, node)
          acceptable = ["`Time.zone.#{safe_method(method_name, node)}`", "`#{klass}.current`"]

          ACCEPTED_METHODS.each do |am|
            acceptable << "`#{klass}.#{method_name}.#{am}`"
          end

          acceptable
        end

        # Time.new, Time.at, and Time.now can be called with a time zone offset
        # When it is, that should be considered safe
        # Example:
        # Time.new(1988, 3, 15, 3, 0, 0, "-05:00")
        def offset_provided?(node)
          case node.method_name
          when :new
            node.arguments.size == 7 || offset_option_provided?(node)
          when :at, :now
            offset_option_provided?(node)
          end
        end

        def offset_option_provided?(node)
          options = node.last_argument
          options&.hash_type? &&
            options.each_pair.any? do |pair|
              pair.key.sym_type? && pair.key.value == :in && !pair.value.nil_type?
            end
        end

        def replacement(node)
          return 'now' unless node.arguments?

          node.first_argument.str_type? ? 'parse' : 'local'
        end
      end
    end
  end
end
