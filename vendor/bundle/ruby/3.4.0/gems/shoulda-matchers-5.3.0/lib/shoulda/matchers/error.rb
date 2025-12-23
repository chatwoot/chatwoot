module Shoulda
  module Matchers
    # @private
    class Error < StandardError
      def self.create(attributes)
        allocate.tap do |error|
          attributes.each do |name, value|
            error.__send__("#{name}=", value)
          end

          error.__send__(:initialize)
        end
      end

      def initialize(*args)
        super
        @message = message
      end

      def message
        ''
      end

      def inspect
        %(#<#{self.class}: #{message}>)
      end
    end
  end
end
