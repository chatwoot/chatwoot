module SafeYAML
  class Parse
    class Hexadecimal
      MATCHER = /\A[-+]?0x[0-9a-fA-F_]+\Z/.freeze

      def self.value(value)
        # This is safe to do since we already validated the value.
        return Integer(value.gsub(/_/, ""))
      end
    end
  end
end
