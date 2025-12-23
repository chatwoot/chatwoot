module ChildProcess
  module Unix
    class IO < AbstractIO
      private

      def check_type(io)
        unless io.respond_to? :to_io
          raise ArgumentError, "expected #{io.inspect} to respond to :to_io"
        end

        result = io.to_io
        unless result && result.kind_of?(::IO)
          raise TypeError, "expected IO, got #{result.inspect}:#{result.class}"
        end
      end

    end # IO
  end # Unix
end # ChildProcess


