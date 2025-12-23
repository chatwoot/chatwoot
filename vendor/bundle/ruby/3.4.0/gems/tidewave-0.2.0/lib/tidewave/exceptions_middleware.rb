# frozen_string_literal: true

class Tidewave::ExceptionsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    status, headers, body = @app.call(env)

    exception = request.get_header("tidewave.exception")

    if exception
      formatted = format_exception_html(exception, request)
      body, headers = append_body(body, headers, formatted)
    end

    [ status, headers, body ]
  rescue => error
    Rails.logger.error("Failure in Tidewave::ExceptionsMiddleware, message: #{error.message}")
    raise error
  end

  private

  def format_exception_html(exception, request)
    backtrace = Rails.backtrace_cleaner.clean(exception.backtrace)

    parameters = request_parameters(request)

    text = exception.class.name.dup

    if parameters["controller"]
      text << " in #{parameters["controller"].camelize}Controller"

      if parameters["action"]
        text << "##{parameters["action"]}"
      end
    end

    text << "\n\n## Message\n\n#{exception.message}"

    if backtrace.any?
      text << "\n\n## Backtrace\n\n#{backtrace.join("\n")}"
    end

    text << "\n\n"

    text << <<~TEXT.chomp
      ## Request info

        * URI: #{request.base_url + request.path}
        * Query string: #{request.query_string}

      ## Session

          #{request.session.to_hash.inspect}
    TEXT

    %Q(<textarea style="display: none;" data-tidewave-exception-info>#{ERB::Util.html_escape(text)}</textarea>)
  end

  def request_parameters(request)
    request.parameters
  rescue ActionController::BadRequest
    {}
  end

  def append_body(body, headers, content)
    new_body = "".dup

    body.each { |part| new_body << part }
    body.close if body.respond_to?(:close)

    if position = new_body.rindex("</body>")
      new_body.insert(position, content)
    else
      new_body << content
    end

    if headers[Rack::CONTENT_LENGTH]
      headers[Rack::CONTENT_LENGTH] = new_body.bytesize.to_s
    end

    [ [ new_body ], headers ]
  end
end
