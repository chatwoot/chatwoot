# frozen_string_literal: true

module MetaRequest
  module LogInterceptor
    def debug(message = nil, *args)
      push_event(:debug, message)
      super
    end

    def info(message = nil, *args)
      push_event(:info, message)
      super
    end

    def warn(message = nil, *args)
      push_event(:warn, message)
      super
    end

    def error(message = nil, *args)
      push_event(:error, message)
      super
    end

    def fatal(message = nil, *args)
      push_event(:fatal, message)
      super
    end

    def unknown(message = nil, *args)
      push_event(:unknown, message)
      super
    end

    private

    def push_event(level, message)
      callsite = AppRequest.current && Utils.dev_callsite(caller.drop(1))
      if callsite
        payload = callsite.merge(message: message, level: level)
        AppRequest.current.events << Event.new('meta_request.log', 0, 0, 0, payload)
      end
    rescue StandardError => e
      MetaRequest.config.logger.fatal(e.message + "\n " + e.backtrace.join("\n "))
    end
  end
end
