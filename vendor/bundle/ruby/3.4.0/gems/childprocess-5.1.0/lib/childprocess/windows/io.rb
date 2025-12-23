module ChildProcess
  module Windows
    class IO < AbstractIO
      private

      def check_type(io)
        return if has_fileno?(io)
        return if has_to_io?(io)

        raise ArgumentError, "#{io.inspect}:#{io.class} must have :fileno or :to_io"
      end

      def has_fileno?(io)
        io.respond_to?(:fileno) && io.fileno
      end

      def has_to_io?(io)
        io.respond_to?(:to_io) && io.to_io.kind_of?(::IO)
      end

    end # IO
  end # Windows
end # ChildProcess


