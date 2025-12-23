# frozen_string_literal: true

module WebMock
  class RackResponse < Response
    def initialize(app)
      @app = app
    end

    def evaluate(request)
      env = build_rack_env(request)

      status, headers, response = @app.call(env)

      Response.new(
        body: body_from_rack_response(response),
        headers: headers,
        status: [status, Rack::Utils::HTTP_STATUS_CODES[status]]
      )
    end

    def body_from_rack_response(response)
      body = "".dup
      response.each { |line| body << line }
      response.close if response.respond_to?(:close)
      return body
    end

    def build_rack_env(request)
      uri = request.uri
      headers = (request.headers || {}).dup
      body = request.body || ''

      env = {
        # CGI variables specified by Rack
        'REQUEST_METHOD' => request.method.to_s.upcase,
        'CONTENT_TYPE'   => headers.delete('Content-Type'),
        'CONTENT_LENGTH' => body.bytesize,
        'PATH_INFO'      => uri.path,
        'QUERY_STRING'   => uri.query || '',
        'SERVER_NAME'    => uri.host,
        'SERVER_PORT'    => uri.port,
        'SCRIPT_NAME'    => ""
      }

      env['HTTP_AUTHORIZATION'] = 'Basic ' + [uri.userinfo].pack('m').delete("\r\n") if uri.userinfo

      # Rack-specific variables
      env['rack.input']      = StringIO.new(body)
      env['rack.errors']     = $stderr
      if !Rack.const_defined?(:RELEASE) || Rack::RELEASE < "3"
        env['rack.version']    = Rack::VERSION
      end
      env['rack.url_scheme'] = uri.scheme
      env['rack.run_once']   = true
      env['rack.session']    = session
      env['rack.session.options'] = session_options

      headers.each do |k, v|
        env["HTTP_#{k.tr('-','_').upcase}"] = v
      end

      env
    end

    def session
      @session ||= {}
    end

    def session_options
      @session_options ||= {}
    end
  end
end
