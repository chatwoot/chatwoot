module ScoutApm
  module Remote
    class Router
      attr_reader :logger
      attr_reader :routes

      # If/When we add different types, this signature should change to a hash
      # of {type => Object}, rather than building it in the initializer here.
      #
      # Keys of routes should be strings
      def initialize(recorder, logger)
        @routes = {
          'record' => recorder
        }

        @logger = logger
      end

      # A message is a 2 element array [:type, :command, [args]].
      # For this first creation, this should be ['record', 'record', [TrackedRequest]] (the args arg should always be an array, even w/ only 1 item)
      #
      # Where
      #   type: ['recorder']
      #   command: any function supported on that type of object
      #   args: any array of arguments
      #
      # Raises on unknown message
      #
      # Returns whatever the recipient object returns
      def handle(msg)
        message = Remote::Message.decode(msg)
        assert_type(message)
        call_route(message)
      end

      private

      def assert_type(message)
        if ! routes.keys.include?(message.type.to_s)
          raise "Unknown type: #{message.type.to_s}"
        end
      end

      def call_route(message)
        routes[message.type].send(message.command, *message.args)
      end
    end
  end
end
