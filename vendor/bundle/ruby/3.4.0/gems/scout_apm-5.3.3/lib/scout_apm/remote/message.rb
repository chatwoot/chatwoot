module ScoutApm
  module Remote
    class Message
      attr_reader :type
      attr_reader :command
      attr_reader :args

      def initialize(type, command, *args)
        @type = type
        @command = command
        @args = args
      end

      def self.decode(msg)
        Marshal.load(msg)
      end

      def encode
        Marshal.dump(self)
      rescue
        ScoutApm::Agent.instance.logger.info("Failed Marshalling Remote::Message")
        ScoutApm::Agent.instance.logger.info(ScoutApm::Utils::MarshalLogging.new(self).dive) rescue nil
        raise
      end
    end
  end
end
