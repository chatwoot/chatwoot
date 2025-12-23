# frozen_string_literal: true

require 'erb'

require_relative 'constants'
require_relative 'utils'
require_relative 'request'
require_relative 'body_proxy'

module Rack
  # Rack::ShowStatus catches all empty responses and replaces them
  # with a site explaining the error.
  #
  # Additional details can be put into <tt>rack.showstatus.detail</tt>
  # and will be shown as HTML.  If such details exist, the error page
  # is always rendered, even if the reply was not empty.

  class ShowStatus
    def initialize(app)
      @app = app
      @template = ERB.new(TEMPLATE)
    end

    def call(env)
      status, headers, body = response = @app.call(env)
      empty = headers[CONTENT_LENGTH].to_i <= 0

      # client or server error, or explicit message
      if (status.to_i >= 400 && empty) || env[RACK_SHOWSTATUS_DETAIL]
        # This double assignment is to prevent an "unused variable" warning.
        # Yes, it is dumb, but I don't like Ruby yelling at me.
        req = req = Rack::Request.new(env)

        message = Rack::Utils::HTTP_STATUS_CODES[status.to_i] || status.to_s

        # This double assignment is to prevent an "unused variable" warning.
        # Yes, it is dumb, but I don't like Ruby yelling at me.
        detail = detail = env[RACK_SHOWSTATUS_DETAIL] || message

        html = @template.result(binding)
        size = html.bytesize

        response[2] = Rack::BodyProxy.new([html]) do
          body.close if body.respond_to?(:close)
        end

        headers[CONTENT_TYPE] = "text/html"
        headers[CONTENT_LENGTH] = size.to_s
      end

      response
    end

    def h(obj)                  # :nodoc:
      case obj
      when String
        Utils.escape_html(obj)
      else
        Utils.escape_html(obj.inspect)
      end
    end

    # :stopdoc:

# adapted from Django <www.djangoproject.com>
# Copyright (c) Django Software Foundation and individual contributors.
# Used under the modified BSD license:
# http://www.xfree86.org/3.3.6/COPYRIGHT2.html#5
TEMPLATE = <<'HTML'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <title><%=h message %> at <%=h req.script_name + req.path_info %></title>
  <meta name="robots" content="NONE,NOARCHIVE" />
  <style type="text/css">
    html * { padding:0; margin:0; }
    body * { padding:10px 20px; }
    body * * { padding:0; }
    body { font:small sans-serif; background:#eee; }
    body>div { border-bottom:1px solid #ddd; }
    h1 { font-weight:normal; margin-bottom:.4em; }
    h1 span { font-size:60%; color:#666; font-weight:normal; }
    table { border:none; border-collapse: collapse; width:100%; }
    td, th { vertical-align:top; padding:2px 3px; }
    th { width:12em; text-align:right; color:#666; padding-right:.5em; }
    #info { background:#f6f6f6; }
    #info ol { margin: 0.5em 4em; }
    #info ol li { font-family: monospace; }
    #summary { background: #ffc; }
    #explanation { background:#eee; border-bottom: 0px none; }
  </style>
</head>
<body>
  <div id="summary">
    <h1><%=h message %> <span>(<%= status.to_i %>)</span></h1>
    <table class="meta">
      <tr>
        <th>Request Method:</th>
        <td><%=h req.request_method %></td>
      </tr>
      <tr>
        <th>Request URL:</th>
      <td><%=h req.url %></td>
      </tr>
    </table>
  </div>
  <div id="info">
    <p><%=h detail %></p>
  </div>

  <div id="explanation">
    <p>
    You're seeing this error because you use <code>Rack::ShowStatus</code>.
    </p>
  </div>
</body>
</html>
HTML
  end
end
