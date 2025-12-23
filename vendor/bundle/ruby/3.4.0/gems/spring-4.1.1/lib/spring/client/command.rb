require "spring/env"

module Spring
  module Client
    class Command
      def self.call(args)
        new(args).call
      end

      attr_reader :args, :env

      def initialize(args)
        @args = args
        @env  = Env.new
      end
    end
  end
end
