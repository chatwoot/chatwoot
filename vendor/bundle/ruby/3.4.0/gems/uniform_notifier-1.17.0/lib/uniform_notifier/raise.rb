# frozen_string_literal: true

class UniformNotifier
  class Raise < Base
    class << self
      def active?
        defined?(@exception_class) ? @exception_class : false
      end

      def setup_connection(exception_class)
        @exception_class = exception_class == true ? Exception : exception_class
      end

      protected

      def _out_of_channel_notify(data)
        message = data.values.compact.join("\n")

        raise @exception_class, message
      end
    end
  end
end
