require_relative "base"

module Administrate
  module Field
    class Time < Base
      def time
        return I18n.localize(data, format: format) if options[:format]

        data.strftime("%I:%M%p")
      end

      private

      def format
        options[:format]
      end
    end
  end
end
