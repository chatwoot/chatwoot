# frozen_string_literal: true

module Twilio
  class Request
    attr_reader :host, :port, :method, :url, :params, :data, :headers, :auth, :timeout

    def initialize(host, port, method, url, params = {}, data = {}, headers = {}, auth = nil, timeout = nil)
      @host = host
      @port = port
      @url = url
      @method = method
      @params = params
      @data = data
      @headers = headers
      @auth = auth
      @timeout = timeout
    end

    def to_s
      auth = @auth.nil? ? '' : '(' + @auth.join(',') + ')'

      params = ''
      unless @params.nil? || @params.empty?
        params = '?' + @params.each.map { |key, value| "#{CGI.escape(key)}=#{CGI.escape(value)}" }.join('&')
      end

      headers = ''
      unless @headers.nil? || @headers.empty?
        headers = "\n" + @headers.each.map { |key, value| "-H \"#{key}\": \"#{value}\"" }.join("\n")
      end

      data = ''
      unless @data.nil? || @data.empty?
        data = @method.equal?('GET') ? "\n -G" : "\n"
        data += case @headers['Content-Type']
                when 'application/x-www-form-urlencoded'
                  @data.each.map { |key, value| "-d \"#{key}\"=\"#{value}\"" }.join("\n")
                when 'application/json'
                  "-d '#{JSON.generate(@data)}'"
                else
                  @data.each.map { |key, value| "-d \"#{key}\"=\"#{value}\"" }.join("\n")
                end
      end

      "#{auth} #{@method} #{@url}#{params}#{data}#{headers}"
    end
  end
end
