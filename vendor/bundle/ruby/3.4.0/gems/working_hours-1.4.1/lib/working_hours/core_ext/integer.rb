require "working_hours/duration_proxy"

module WorkingHours
  module CoreExt
    module Integer

      def working
        WorkingHours::DurationProxy.new(self)
      end

    end
  end
end

Integer.send(:include, WorkingHours::CoreExt::Integer)
