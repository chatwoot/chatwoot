require 'active_support/time_with_zone'
require 'working_hours/module'

module WorkingHours
  module CoreExt
    module DateAndTime

      def self.included base
        base.class_eval do
          alias_method :minus_without_working_hours, :-
          alias_method :-, :minus_with_working_hours
          alias_method :plus_without_working_hours, :+
          alias_method :+, :plus_with_working_hours
        end
      end

      def plus_with_working_hours(other)
        if WorkingHours::Duration === other
          other.since(self)
        else
          plus_without_working_hours(other)
        end
      end

      def minus_with_working_hours(other)
        if WorkingHours::Duration === other
          other.until(self)
        else
          minus_without_working_hours(other)
        end
      end

      def working_days_until(other)
        WorkingHours.working_days_between(self, other)
      end

      def working_time_until(other)
        WorkingHours.working_time_between(self, other)
      end

      def working_day?
        WorkingHours.working_day?(self)
      end

      def in_working_hours?
        WorkingHours.in_working_hours?(self)
      end
    end
  end
end

class Date
  include WorkingHours::CoreExt::DateAndTime
end

class Time
  include WorkingHours::CoreExt::DateAndTime
end

class ActiveSupport::TimeWithZone
  include WorkingHours::CoreExt::DateAndTime
end
