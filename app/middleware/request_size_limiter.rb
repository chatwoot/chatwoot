class RequestSizeLimiter
  # Only apply to kb_resources upload endpoint
  KB_RESOURCES_PATH = %r{/api/v1/accounts/\d+/kb_resources\z}.freeze
  MAX_SIZE = 200.megabytes

  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless applies_to?(env)

    # Check Content-Length header first (can be spoofed, but quick check)
    content_length = env['CONTENT_LENGTH'].to_i
    if content_length > MAX_SIZE
      return [413, { 'Content-Type' => 'application/json' },
              [{ error: "Request too large. Maximum size is #{MAX_SIZE / 1.megabyte}MB" }.to_json]]
    end

    # Wrap the input stream to count bytes and cut off if exceeded
    original_input = env['rack.input']
    env['rack.input'] = LimitedInputStream.new(original_input, MAX_SIZE)

    @app.call(env)
  rescue LimitedInputStream::SizeLimitExceeded
    [413, { 'Content-Type' => 'application/json' },
     [{ error: "Upload exceeded maximum size of #{MAX_SIZE / 1.megabyte}MB" }.to_json]]
  end

  private

  def applies_to?(env)
    env['REQUEST_METHOD'] == 'POST' && env['PATH_INFO'].match?(KB_RESOURCES_PATH)
  end

  class LimitedInputStream
    class SizeLimitExceeded < StandardError; end

    def initialize(input, limit)
      @input = input
      @limit = limit
      @bytes_read = 0
    end

    def read(length = nil, buffer = nil)
      data = @input.read(length, buffer)
      return data if data.nil?

      @bytes_read += data.bytesize
      raise SizeLimitExceeded if @bytes_read > @limit

      data
    end

    def gets
      data = @input.gets
      return data if data.nil?

      @bytes_read += data.bytesize
      raise SizeLimitExceeded if @bytes_read > @limit

      data
    end

    def rewind
      @input.rewind
      @bytes_read = 0
    end

    def size
      @input.size
    end

    def eof?
      @input.eof?
    end
  end
end
