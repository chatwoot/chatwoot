module ScoutApm
  module Utils
    class Time
      # Handles both integer (unix) time and Time objects
      # example output:  "09/10/15 04:34:28 -0600"
      def self.to_s(time)
        return to_s(::Time.at(time)) if time.is_a? Integer
        time.strftime("%m/%d/%y %H:%M:%S %z")
      end
    end
  end
end
