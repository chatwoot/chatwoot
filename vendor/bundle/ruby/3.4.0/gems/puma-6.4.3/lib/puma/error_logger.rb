# frozen_string_literal: true

require_relative 'const'

module Puma
  # The implementation of a detailed error logging.
  # @version 5.0.0
  #
  class ErrorLogger
    include Const

    attr_reader :ioerr

    REQUEST_FORMAT = %{"%s %s%s" - (%s)}

    LOG_QUEUE = Queue.new

    def initialize(ioerr)
      @ioerr = ioerr

      @debug = ENV.key? 'PUMA_DEBUG'
    end

    def self.stdio
      new $stderr
    end

    # Print occurred error details.
    # +options+ hash with additional options:
    # - +error+ is an exception object
    # - +req+ the http request
    # - +text+ (default nil) custom string to print in title
    #   and before all remaining info.
    #
    def info(options={})
      internal_write title(options)
    end

    # Print occurred error details only if
    # environment variable PUMA_DEBUG is defined.
    # +options+ hash with additional options:
    # - +error+ is an exception object
    # - +req+ the http request
    # - +text+ (default nil) custom string to print in title
    #   and before all remaining info.
    #
    def debug(options={})
      return unless @debug

      error = options[:error]
      req = options[:req]

      string_block = []
      string_block << title(options)
      string_block << request_dump(req) if request_parsed?(req)
      string_block << error.backtrace if error

      internal_write string_block.join("\n")
    end

    def title(options={})
      text = options[:text]
      req = options[:req]
      error = options[:error]

      string_block = ["#{Time.now}"]
      string_block << " #{text}" if text
      string_block << " (#{request_title(req)})" if request_parsed?(req)
      string_block << ": #{error.inspect}" if error
      string_block.join('')
    end

    def request_dump(req)
      "Headers: #{request_headers(req)}\n" \
      "Body: #{req.body}"
    end

    def request_title(req)
      env = req.env

      REQUEST_FORMAT % [
        env[REQUEST_METHOD],
        env[REQUEST_PATH] || env[PATH_INFO],
        env[QUERY_STRING] || "",
        env[HTTP_X_FORWARDED_FOR] || env[REMOTE_ADDR] || "-"
      ]
    end

    def request_headers(req)
      headers = req.env.select { |key, _| key.start_with?('HTTP_') }
      headers.map { |key, value| [key[5..-1], value] }.to_h.inspect
    end

    def request_parsed?(req)
      req && req.env[REQUEST_METHOD]
    end

    def internal_write(str)
      LOG_QUEUE << str
      while (w_str = LOG_QUEUE.pop(true)) do
        begin
          @ioerr.is_a?(IO) and @ioerr.wait_writable(1)
          @ioerr.write "#{w_str}\n"
          @ioerr.flush unless @ioerr.sync
        rescue Errno::EPIPE, Errno::EBADF, IOError, Errno::EINVAL
        # 'Invalid argument' (Errno::EINVAL) may be raised by flush
        end
      end
    rescue ThreadError
    end
    private :internal_write
  end
end
