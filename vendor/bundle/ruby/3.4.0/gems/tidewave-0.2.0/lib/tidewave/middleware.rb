# frozen_string_literal: true

require "open3"
require "ipaddr"
require "fast_mcp"
require "rack/request"
require "active_support/core_ext/class"
require "active_support/core_ext/object/blank"
require "json"
require "erb"

class Tidewave::Middleware
  TIDEWAVE_ROUTE = "tidewave".freeze
  EMPTY_ROUTE = "empty".freeze
  SSE_ROUTE = "mcp".freeze
  MESSAGES_ROUTE = "mcp/message".freeze
  SHELL_ROUTE = "shell".freeze

  INVALID_IP = <<~TEXT.freeze
    For security reasons, Tidewave does not accept remote connections by default.

    If you really want to allow remote connections, set `config.tidewave.allow_remote_access = true`.
  TEXT

  def initialize(app, config)
    @allow_remote_access = config.allow_remote_access
    @client_url = config.client_url
    @project_name = Rails.application.class.module_parent.name

    @app = FastMcp.rack_middleware(app,
      name: "tidewave",
      version: Tidewave::VERSION,
      path_prefix: "/" + TIDEWAVE_ROUTE,
      messages_route: MESSAGES_ROUTE,
      sse_route: SSE_ROUTE,
      logger: config.logger || Logger.new(Rails.root.join("log", "tidewave.log")),
      # Rails runs the HostAuthorization in dev, so we skip this
      allowed_origins: [],
      # We validate this one in Tidewave::Middleware
      localhost_only: false
    ) do |server|
      server.filter_tools do |request, tools|
        if request.params["include_fs_tools"] != "true"
          tools.reject { |tool| tool.tags.include?(:file_system_tool) }
        else
          tools
        end
      end

      server.register_tools(*Tidewave::Tools::Base.descendants)
    end
  end

  def call(env)
    request = Rack::Request.new(env)
    path = request.path.split("/").reject(&:empty?)

    if path[0] == TIDEWAVE_ROUTE
      return forbidden(INVALID_IP) unless valid_client_ip?(request)

      # The MCP routes are handled downstream by FastMCP
      case [ request.request_method, path ]
      when [ "GET", [ TIDEWAVE_ROUTE ] ]
        return home(request)
      when [ "GET", [ TIDEWAVE_ROUTE, EMPTY_ROUTE ] ]
        return empty(request)
      when [ "POST", [ TIDEWAVE_ROUTE, SHELL_ROUTE ] ]
        return shell(request)
      end
    end

    @app.call(env)
  end

  private

  def home(request)
    config = {
      "project_name" => @project_name,
      "framework_type" => "rails",
      "tidewave_version" => Tidewave::VERSION
    }

    html = <<~HTML
      <html>
        <head>
          <meta charset="UTF-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <meta name="tidewave:config" content="#{ERB::Util.html_escape(JSON.generate(config))}" />
          <script type="module" src="#{@client_url}/tc/tc.js"></script>
        </head>
        <body></body>
      </html>
    HTML

    [ 200, { "Content-Type" => "text/html" }, [ html ] ]
  end

  def empty(request)
    html = ""
    [ 200, { "Content-Type" => "text/html" }, [ html ] ]
  end

  def forbidden(message)
    Rails.logger.warn(message)
    [ 403, { "Content-Type" => "text/plain" }, [ message ] ]
  end

  def shell(request)
    body = request.body.read
    return [ 400, { "Content-Type" => "text/plain" }, [ "Command body is required" ] ] if body.blank?

    begin
      parsed_body = JSON.parse(body)
      cmd = parsed_body["command"]
      return [ 400, { "Content-Type" => "text/plain" }, [ "Command field is required" ] ] if cmd.blank?
    rescue JSON::ParserError
      return [ 400, { "Content-Type" => "text/plain" }, [ "Invalid JSON in request body" ] ]
    end

    response = Rack::Response.new
    response.status = 200
    response.headers["Content-Type"] = "text/plain"

    response.finish do |res|
      begin
        Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thr|
          stdin.close

          # Merge stdout and stderr streams
          ios = [ stdout, stderr ]

          until ios.empty?
            ready = IO.select(ios, nil, nil, 0.1)
            next unless ready

            ready[0].each do |io|
              begin
                data = io.read_nonblock(4096)
                if data
                  # Write binary chunk: type (0 for data) + 4-byte length + data
                  chunk = [ 0, data.bytesize ].pack("CN") + data
                  res.write(chunk)
                end
              rescue IO::WaitReadable
                # No data available right now
              rescue EOFError
                # Stream ended
                ios.delete(io)
              end
            end
          end

          # Wait for process to complete and get exit status
          exit_status = wait_thr.value.exitstatus
          status_json = JSON.generate({ status: exit_status })
          # Write binary chunk: type (1 for status) + 4-byte length + JSON data
          chunk = [ 1, status_json.bytesize ].pack("CN") + status_json
          res.write(chunk)
        end
      rescue => e
        error_json = JSON.generate({ status: 213 })
        chunk = [ 1, error_json.bytesize ].pack("CN") + error_json
        res.write(chunk)
      end
    end
  end

  def valid_client_ip?(request)
    return true if @allow_remote_access

    ip = request.ip
    return false unless ip

    addr = IPAddr.new(ip)

    addr.loopback? ||
    addr == IPAddr.new("127.0.0.1") ||
    addr == IPAddr.new("::1") ||
    addr == IPAddr.new("::ffff:127.0.0.1")  # IPv4-mapped IPv6
  end
end
