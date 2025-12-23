# Serialize & deserialize commands from the APM server to the instrumented app

module ScoutApm
  module Serializers
    class AppServerLoadSerializer
      def self.serialize(data)
        Marshal.dump(data)
      rescue
        ScoutApm::Agent.instance.logger.info("Failed Marshalling AppServerLoad")
        ScoutApm::Agent.instance.logger.info(ScoutApm::Utils::MarshalLogging.new(data).dive) rescue nil
        raise
      end

      def self.deserialize(data)
        Marshal.load(data)
      end
    end
  end
end
