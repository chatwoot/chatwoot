# frozen_string_literal: true

require 'rack/request'
require 'json'
require 'cgi'

module Bullet
  class Rack
    include Dependency

    NONCE_MATCHER = /(script|style)-src .*'nonce-(?<nonce>[A-Za-z0-9+\/]+={0,2})'/

    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) unless Bullet.enable?

      Bullet.start_request
      status, headers, response = @app.call(env)

      response_body = nil

      if Bullet.notification? || Bullet.always_append_html_body
        request = ::Rack::Request.new(env)
        if Bullet.inject_into_page? && !skip_html_injection?(request) && !file?(headers) && !sse?(headers) && !empty?(response) && status == 200
          if html_request?(headers, response)
            response_body = response_body(response)

            with_security_policy_nonce(headers) do |nonce|
              response_body = append_to_html_body(response_body, footer_note(nonce)) if Bullet.add_footer
              response_body = append_to_html_body(response_body, Bullet.gather_inline_notifications)
              if Bullet.add_footer && !Bullet.skip_http_headers
                response_body = append_to_html_body(response_body, xhr_script(nonce))
              end
            end

            headers['Content-Length'] = response_body.bytesize.to_s
          elsif !Bullet.skip_http_headers
            set_header(headers, 'X-bullet-footer-text', Bullet.footer_info.uniq) if Bullet.add_footer
            set_header(headers, 'X-bullet-console-text', Bullet.text_notifications) if Bullet.console_enabled?
          end
        end
        Bullet.perform_out_of_channel_notifications(env)
      end
      [status, headers, response_body ? [response_body] : response]
    ensure
      Bullet.end_request
    end

    # fix issue if response's body is a Proc
    def empty?(response)
      # response may be ["Not Found"], ["Move Permanently"], etc, but
      # those should not happen if the status is 200
      return true if !response.respond_to?(:body) && !response.respond_to?(:first)

      body = response_body(response)
      body.nil? || body.empty?
    end

    def append_to_html_body(response_body, content)
      body = response_body.dup
      content = content.html_safe if content.respond_to?(:html_safe)
      if body.include?('</body>')
        position = body.rindex('</body>')
        body.insert(position, content)
      else
        body << content
      end
    end

    def footer_note(nonce = nil)
      %(<details id="bullet-footer" data-is-bullet-footer><summary>Bullet Warnings</summary><div>#{Bullet.footer_info.uniq.join('<br>')}#{footer_console_message(nonce)}</div>#{footer_style(nonce)}</details>)
    end

    # Make footer styles work with ContentSecurityPolicy style-src as self
    def footer_style(nonce = nil)
      css = <<~CSS
        details#bullet-footer {cursor: pointer; position: fixed; left: 0px; bottom: 0px; z-index: 9999; background: #fdf2f2; color: #9b1c1c; font-size: 12px; border-radius: 0px 8px 0px 0px; border: 1px solid #9b1c1c;}
        details#bullet-footer summary {font-weight: 600; padding: 2px 8px;}
        details#bullet-footer div {padding: 8px; border-top: 1px solid #9b1c1c;}
      CSS
      if nonce
        %(<style type="text/css" nonce="#{nonce}">#{css}</style>)
      else
        %(<style type="text/css">#{css}</style>)
      end
    end

    def set_header(headers, header_name, header_array)
      # Many proxy applications such as Nginx and AWS ELB limit
      # the size a header to 8KB, so truncate the list of reports to
      # be under that limit
      header_array.pop while JSON.generate(header_array).length > 8 * 1024
      headers[header_name] = JSON.generate(header_array)
    end

    def skip_html_injection?(request)
      query_string = request.env['QUERY_STRING']
      return false if query_string.nil? || query_string.empty?

      params = simple_parse_query_string(query_string)
      params['skip_html_injection'] == 'true'
    end

    # Simple query string parser
    def simple_parse_query_string(query_string)
      params = {}
      query_string.split('&').each do |pair|
        key, value = pair.split('=', 2).map { |s| CGI.unescape(s) }
        params[key] = value if key && !key.empty?
      end
      params
    end

    def file?(headers)
      headers['Content-Transfer-Encoding'] == 'binary' || headers['Content-Disposition']
    end

    def sse?(headers)
      headers['Content-Type'] == 'text/event-stream'
    end

    def html_request?(headers, response)
      headers['Content-Type']&.include?('text/html')
    end

    def response_body(response)
      if response.respond_to?(:body)
        Array === response.body ? response.body.first : response.body
      elsif response.respond_to?(:first)
        response.first
      end
    end

    private

    def footer_console_message(nonce = nil)
      if Bullet.console_enabled?
        footer = %(<br/><span id="console-message">See 'Uniform Notifier' in JS Console for Stacktrace</span>)
        css = "details#bullet-footer #console-message {font-style: italic;}"
        style =
          if nonce
            %(<style type="text/css" nonce="#{nonce}">#{css}</style>)
          else
            %(<style type="text/css">#{css}</style>)
          end

        footer + style
      end
    end

    # Make footer work for XHR requests by appending data to the footer
    def xhr_script(nonce = nil)
      script = File.read("#{__dir__}/bullet_xhr.js")

      if nonce
        "<script type='text/javascript' nonce='#{nonce}'>#{script}</script>"
      else
        "<script type='text/javascript'>#{script}</script>"
      end
    end

    def with_security_policy_nonce(headers)
      csp = headers['Content-Security-Policy'] || headers['Content-Security-Policy-Report-Only'] || ''
      matched = csp.match(NONCE_MATCHER)
      nonce = matched[:nonce] if matched

      if nonce
        console_enabled = UniformNotifier.console
        alert_enabled = UniformNotifier.alert

        UniformNotifier.console = { attributes: { nonce: nonce } } if console_enabled
        UniformNotifier.alert = { attributes: { nonce: nonce } } if alert_enabled

        yield nonce

        UniformNotifier.console = console_enabled
        UniformNotifier.alert = alert_enabled
      else
        yield
      end
    end
  end
end
