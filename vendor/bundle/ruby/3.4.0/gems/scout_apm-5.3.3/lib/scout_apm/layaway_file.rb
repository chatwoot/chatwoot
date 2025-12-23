# A single layaway file.  See Layaway for the management of the group of files.
module ScoutApm
  class LayawayFile
    attr_reader :path
    attr_reader :context

    def initialize(context, path)
      @path = path
      @context = context
    end

    def logger
      context.logger
    end

    def load
      data = File.open(path, "r") { |f| read_raw(f) }
      deserialize(data)
    rescue NameError, ArgumentError, TypeError => e
      # Marshal error
      logger.info("LayawayFile: Unable to load data")
      logger.debug("#{e.message}, #{e.backtrace.join("\n\t")}")
      nil
    end

    def write(data)
      serialized_data = serialize(data)
      File.open(path, "w") { |f| write_raw(f, serialized_data) }
    end

    def serialize(data)
      Marshal.dump(data)
    rescue
      ScoutApm::Agent.instance.logger.info("Failed Marshalling LayawayFile")
      ScoutApm::Agent.instance.logger.info(ScoutApm::Utils::MarshalLogging.new(data).dive) rescue nil
      raise
    end

    def deserialize(data)
      Marshal.load(data)
    end

    def read_raw(f)
      contents = ""
      while true
        contents << f.read_nonblock(10_000)
      end
    rescue Errno::EAGAIN, Errno::EINTR
      IO.select([f])
      retry
    rescue EOFError
      contents
    end

    def write_raw(f, data)
      result = 0
      while (result < data.length)
        result += f.write_nonblock(data)
      end
    rescue Errno::EAGAIN, Errno::EINTR
      IO.select(nil, [f])
      retry
    end
  end
end

