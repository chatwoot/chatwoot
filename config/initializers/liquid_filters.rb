# Registers global Liquid filters available to all template renders.
# Filters added here are accessible inside any {{ value | filter }} expression.
module LiquidFilters
  module DateFilter
    # Formats a date/time/string with a strftime pattern.
    # Usage: {{ date.today | date: "%Y-%m-%d" }} -> "2026-07-21"
    # Usage: {{ contact.created_at | date: "%d/%m/%Y" }} -> "21/07/2026"
    def date(input, format = '%Y-%m-%d')
      return '' if input.blank?

      Time.zone.parse(input.to_s).strftime(format)
    rescue ArgumentError, TypeError
      input.to_s
    end

    # Returns the input date plus N days.
    # Usage: {{ date.today | plus_days: 7 }} -> 7 days from today
    def plus_days(input, days = 0)
      return input if input.blank?

      base = input.is_a?(String) ? Time.zone.parse(input.to_s) : input.to_time
      (base + days.to_i.days).to_date
    rescue ArgumentError, TypeError
      input
    end

    # Returns the input date minus N days.
    # Usage: {{ date.today | minus_days: 30 }} -> 30 days ago
    def minus_days(input, days = 0)
      plus_days(input, -days.to_i)
    end
  end
end

Liquid::Template.register_filter(LiquidFilters::DateFilter)
