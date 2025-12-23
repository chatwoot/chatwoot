# frozen_string_literal: true

require_relative "parse"

module Byebug
  module Helpers
    #
    # Utilities to assist breakpoint/display enabling/disabling.
    #
    module ToggleHelper
      include ParseHelper

      def enable_disable_breakpoints(is_enable, args)
        raise pr("toggle.errors.no_breakpoints") if Breakpoint.none?

        select_breakpoints(is_enable, args).each do |b|
          enabled = (is_enable == "enable")
          raise pr("toggle.errors.expression", expr: b.expr) if enabled && !syntax_valid?(b.expr)

          puts pr("toggle.messages.toggled", bpnum: b.id,
                                             endis: enabled ? "en" : "dis")
          b.enabled = enabled
        end
      end

      def enable_disable_display(is_enable, args)
        raise pr("toggle.errors.no_display") if n_displays.zero?

        selected_displays = args ? args.split(/ +/) : [1..n_displays + 1]

        selected_displays.each do |pos|
          pos, err = get_int(pos, "#{is_enable} display", 1, n_displays)
          raise err unless err.nil?

          Byebug.displays[pos - 1][0] = (is_enable == "enable")
        end
      end

      private

      def select_breakpoints(is_enable, args)
        all_breakpoints = Byebug.breakpoints.sort_by(&:id)
        return all_breakpoints if args.nil?

        selected_ids = []
        args.split(/ +/).each do |pos|
          last_id = all_breakpoints.last.id
          pos, err = get_int(pos, "#{is_enable} breakpoints", 1, last_id)
          raise(ArgumentError, err) unless pos

          selected_ids << pos
        end

        all_breakpoints.select { |b| selected_ids.include?(b.id) }
      end

      def n_displays
        Byebug.displays.size
      end
    end
  end
end
