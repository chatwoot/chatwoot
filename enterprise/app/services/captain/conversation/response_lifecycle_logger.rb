class Captain::Conversation::ResponseLifecycleLogger
  PREFIX = '[CAPTAIN][ResponseLifecycle]'.freeze

  class << self
    def info(event, **attributes)
      log(:info, event, attributes)
    end

    def error(event, **attributes)
      log(:error, event, attributes)
    end

    private

    def log(level, event, attributes)
      payload = { event: event }.merge(attributes).compact.map do |key, value|
        "#{key}=#{normalize(value)}"
      end.join(' ')

      Rails.logger.public_send(level, "#{PREFIX} #{payload}")
    end

    def normalize(value)
      value.to_s.gsub(/\s+/, '_')
    end
  end
end
