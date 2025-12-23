# frozen_string_literal: true

module Twilio
  module REST
    class ObsoleteClient
      def initialize(*)
        raise ObsoleteError, "#{self.class} has been removed from this version of the library. "\
                             'Please refer to current documentation for guidance.'
      end
    end
  end
end
