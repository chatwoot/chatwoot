# based on https://gist.github.com/mnutt/566725
module Searchkick
  class LogSubscriber < ActiveSupport::LogSubscriber
    def self.runtime=(value)
      Thread.current[:searchkick_runtime] = value
    end

    def self.runtime
      Thread.current[:searchkick_runtime] ||= 0
    end

    def self.reset_runtime
      rt = runtime
      self.runtime = 0
      rt
    end

    def search(event)
      self.class.runtime += event.duration
      return unless logger.debug?

      payload = event.payload
      name = "#{payload[:name]} (#{event.duration.round(1)}ms)"

      index = payload[:query][:index].is_a?(Array) ? payload[:query][:index].join(",") : payload[:query][:index]
      type = payload[:query][:type]
      request_params = payload[:query].except(:index, :type, :body)

      params = []
      request_params.each do |k, v|
        params << "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"
      end

      debug "  #{color(name, YELLOW, bold: true)}  #{index}#{type ? "/#{type.join(',')}" : ''}/_search#{params.any? ? '?' + params.join('&') : nil} #{payload[:query][:body].to_json}"
    end

    def request(event)
      self.class.runtime += event.duration
      return unless logger.debug?

      payload = event.payload
      name = "#{payload[:name]} (#{event.duration.round(1)}ms)"

      debug "  #{color(name, YELLOW, bold: true)}  #{payload.except(:name).to_json}"
    end

    def multi_search(event)
      self.class.runtime += event.duration
      return unless logger.debug?

      payload = event.payload
      name = "#{payload[:name]} (#{event.duration.round(1)}ms)"

      debug "  #{color(name, YELLOW, bold: true)}  _msearch #{payload[:body]}"
    end
  end
end
