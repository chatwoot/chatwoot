require_relative "base"

module Administrate
  module Field
    class Boolean < Base
      def to_s
        if data.nil?
          "-"
        else
          data.to_s
        end
      end
    end
  end
end
