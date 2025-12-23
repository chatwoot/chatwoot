module ScoutApm
  module Utils
    class Numbers

      # Round a float to a certain number of decimal places
      def self.round(number, decimals)
        factor = 10 ** decimals

        (number * factor).round / factor.to_f
      end

    end
  end
end
