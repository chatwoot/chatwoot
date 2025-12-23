# frozen_string_literal: true

module WebConsole
  # Injects content into a Rack body.
  class Injector
    def initialize(body, headers)
      @body = "".dup

      body.each { |part| @body << part }
      body.close if body.respond_to?(:close)

      @headers = headers
    end

    def inject(content)
      # Set content-length header to the size of the current body
      # + the extra content. Otherwise the response will be truncated.
      if @headers[Rack::CONTENT_LENGTH]
        @headers[Rack::CONTENT_LENGTH] = (@body.bytesize + content.bytesize).to_s
      end

      [
        if position = @body.rindex("</body>")
          [ @body.insert(position, content) ]
        else
          [ @body << content ]
        end,
        @headers
      ]
    end
  end
end
