# frozen_string_literal: true

class IO
  # We need to use this for a jruby work around on both 1.8 and 1.9.
  # So this either creates the constant (on 1.8), or harmlessly
  # reopens it (on 1.9).
  module WaitReadable
  end
end

require_relative 'detect'
require_relative 'io_buffer'
require 'tempfile'

if Puma::IS_JRUBY
  # We have to work around some OpenSSL buffer/io-readiness bugs
  # so we pull it in regardless of if the user is binding
  # to an SSL socket
  require 'openssl'
end

module Puma

  class ConnectionError < RuntimeError; end

  class HttpParserError501 < IOError; end

  #———————————————————————— DO NOT USE — this class is for internal use only ———


  # An instance of this class represents a unique request from a client.
  # For example, this could be a web request from a browser or from CURL.
  #
  # An instance of `Puma::Client` can be used as if it were an IO object
  # by the reactor. The reactor is expected to call `#to_io`
  # on any non-IO objects it polls. For example, nio4r internally calls
  # `IO::try_convert` (which may call `#to_io`) when a new socket is
  # registered.
  #
  # Instances of this class are responsible for knowing if
  # the header and body are fully buffered via the `try_to_finish` method.
  # They can be used to "time out" a response via the `timeout_at` reader.
  #
  class Client # :nodoc:

    # this tests all values but the last, which must be chunked
    ALLOWED_TRANSFER_ENCODING = %w[compress deflate gzip].freeze

    # chunked body validation
    CHUNK_SIZE_INVALID = /[^\h]/.freeze
    CHUNK_VALID_ENDING = Const::LINE_END
    CHUNK_VALID_ENDING_SIZE = CHUNK_VALID_ENDING.bytesize

    # The maximum number of bytes we'll buffer looking for a valid
    # chunk header.
    MAX_CHUNK_HEADER_SIZE = 4096

    # The maximum amount of excess data the client sends
    # using chunk size extensions before we abort the connection.
    MAX_CHUNK_EXCESS = 16 * 1024

    # Content-Length header value validation
    CONTENT_LENGTH_VALUE_INVALID = /[^\d]/.freeze

    TE_ERR_MSG = 'Invalid Transfer-Encoding'

    # The object used for a request with no body. All requests with
    # no body share this one object since it has no state.
    EmptyBody = NullIO.new

    include Puma::Const

    def initialize(io, env=nil)
      @io = io
      @to_io = io.to_io
      @io_buffer = IOBuffer.new
      @proto_env = env
      @env = env&.dup

      @parser = HttpParser.new
      @parsed_bytes = 0
      @read_header = true
      @read_proxy = false
      @ready = false

      @body = nil
      @body_read_start = nil
      @buffer = nil
      @tempfile = nil

      @timeout_at = nil

      @requests_served = 0
      @hijacked = false

      @http_content_length_limit = nil
      @http_content_length_limit_exceeded = false

      @peerip = nil
      @peer_family = nil
      @listener = nil
      @remote_addr_header = nil
      @expect_proxy_proto = false

      @body_remain = 0

      @in_last_chunk = false

      # need unfrozen ASCII-8BIT, +'' is UTF-8
      @read_buffer = String.new # rubocop: disable Performance/UnfreezeString
    end

    attr_reader :env, :to_io, :body, :io, :timeout_at, :ready, :hijacked,
                :tempfile, :io_buffer, :http_content_length_limit_exceeded

    attr_writer :peerip, :http_content_length_limit

    attr_accessor :remote_addr_header, :listener

    # Remove in Puma 7?
    def closed?
      @to_io.closed?
    end

    # Test to see if io meets a bare minimum of functioning, @to_io needs to be
    # used for MiniSSL::Socket
    def io_ok?
      @to_io.is_a?(::BasicSocket) && !closed?
    end

    # @!attribute [r] inspect
    def inspect
      "#<Puma::Client:0x#{object_id.to_s(16)} @ready=#{@ready.inspect}>"
    end

    # For the hijack protocol (allows us to just put the Client object
    # into the env)
    def call
      @hijacked = true
      env[HIJACK_IO] ||= @io
    end

    # @!attribute [r] in_data_phase
    def in_data_phase
      !(@read_header || @read_proxy)
    end

    def set_timeout(val)
      @timeout_at = Process.clock_gettime(Process::CLOCK_MONOTONIC) + val
    end

    # Number of seconds until the timeout elapses.
    def timeout
      [@timeout_at - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0].max
    end

    def reset(fast_check=true)
      @parser.reset
      @io_buffer.reset
      @read_header = true
      @read_proxy = !!@expect_proxy_proto
      @env = @proto_env.dup
      @body = nil
      @tempfile = nil
      @parsed_bytes = 0
      @ready = false
      @body_remain = 0
      @peerip = nil if @remote_addr_header
      @in_last_chunk = false
      @http_content_length_limit_exceeded = false

      if @buffer
        return false unless try_to_parse_proxy_protocol

        @parsed_bytes = @parser.execute(@env, @buffer, @parsed_bytes)

        if @parser.finished?
          return setup_body
        elsif @parsed_bytes >= MAX_HEADER
          raise HttpParserError,
            "HEADER is longer than allowed, aborting client early."
        end

        return false
      else
        begin
          if fast_check && @to_io.wait_readable(FAST_TRACK_KA_TIMEOUT)
            return try_to_finish
          end
        rescue IOError
          # swallow it
        end

      end
    end

    def close
      begin
        @io.close
      rescue IOError, Errno::EBADF
        Puma::Util.purge_interrupt_queue
      end
    end

    # If necessary, read the PROXY protocol from the buffer. Returns
    # false if more data is needed.
    def try_to_parse_proxy_protocol
      if @read_proxy
        if @expect_proxy_proto == :v1
          if @buffer.include? "\r\n"
            if md = PROXY_PROTOCOL_V1_REGEX.match(@buffer)
              if md[1]
                @peerip = md[1].split(" ")[0]
              end
              @buffer = md.post_match
            end
            # if the buffer has a \r\n but doesn't have a PROXY protocol
            # request, this is just HTTP from a non-PROXY client; move on
            @read_proxy = false
            return @buffer.size > 0
          else
            return false
          end
        end
      end
      true
    end

    def try_to_finish
      if env[CONTENT_LENGTH] && above_http_content_limit(env[CONTENT_LENGTH].to_i)
        @http_content_length_limit_exceeded = true
      end

      if @http_content_length_limit_exceeded
        @buffer = nil
        @body = EmptyBody
        set_ready
        return true
      end

      return read_body if in_data_phase

      begin
        data = @io.read_nonblock(CHUNK_SIZE)
      rescue IO::WaitReadable
        return false
      rescue EOFError
        # Swallow error, don't log
      rescue SystemCallError, IOError
        raise ConnectionError, "Connection error detected during read"
      end

      # No data means a closed socket
      unless data
        @buffer = nil
        set_ready
        raise EOFError
      end

      if @buffer
        @buffer << data
      else
        @buffer = data
      end

      return false unless try_to_parse_proxy_protocol

      @parsed_bytes = @parser.execute(@env, @buffer, @parsed_bytes)

      if @parser.finished? && above_http_content_limit(@parser.body.bytesize)
        @http_content_length_limit_exceeded = true
      end

      if @parser.finished?
        return setup_body
      elsif @parsed_bytes >= MAX_HEADER
        raise HttpParserError,
          "HEADER is longer than allowed, aborting client early."
      end

      false
    end

    def eagerly_finish
      return true if @ready
      return false unless @to_io.wait_readable(0)
      try_to_finish
    end

    def finish(timeout)
      return if @ready
      @to_io.wait_readable(timeout) || timeout! until try_to_finish
    end

    def timeout!
      write_error(408) if in_data_phase
      raise ConnectionError
    end

    def write_error(status_code)
      begin
        @io << ERROR_RESPONSE[status_code]
      rescue StandardError
      end
    end

    def peerip
      return @peerip if @peerip

      if @remote_addr_header
        hdr = (@env[@remote_addr_header] || @io.peeraddr.last).split(/[\s,]/).first
        @peerip = hdr
        return hdr
      end

      @peerip ||= @io.peeraddr.last
    end

    def peer_family
      return @peer_family if @peer_family

      @peer_family ||= begin
                         @io.local_address.afamily
                       rescue
                         Socket::AF_INET
                       end
    end

    # Returns true if the persistent connection can be closed immediately
    # without waiting for the configured idle/shutdown timeout.
    # @version 5.0.0
    #
    def can_close?
      # Allow connection to close if we're not in the middle of parsing a request.
      @parsed_bytes == 0
    end

    def expect_proxy_proto=(val)
      if val
        if @read_header
          @read_proxy = true
        end
      else
        @read_proxy = false
      end
      @expect_proxy_proto = val
    end

    private

    def setup_body
      @body_read_start = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)

      if @env[HTTP_EXPECT] == CONTINUE
        # TODO allow a hook here to check the headers before
        # going forward
        @io << HTTP_11_100
        @io.flush
      end

      @read_header = false

      body = @parser.body

      te = @env[TRANSFER_ENCODING2]
      if te
        te_lwr = te.downcase
        if te.include? ','
          te_ary = te_lwr.split ','
          te_count = te_ary.count CHUNKED
          te_valid = te_ary[0..-2].all? { |e| ALLOWED_TRANSFER_ENCODING.include? e }
          if te_ary.last == CHUNKED && te_count == 1 && te_valid
            @env.delete TRANSFER_ENCODING2
            return setup_chunked_body body
          elsif te_count >= 1
            raise HttpParserError   , "#{TE_ERR_MSG}, multiple chunked: '#{te}'"
          elsif !te_valid
            raise HttpParserError501, "#{TE_ERR_MSG}, unknown value: '#{te}'"
          end
        elsif te_lwr == CHUNKED
          @env.delete TRANSFER_ENCODING2
          return setup_chunked_body body
        elsif ALLOWED_TRANSFER_ENCODING.include? te_lwr
          raise HttpParserError     , "#{TE_ERR_MSG}, single value must be chunked: '#{te}'"
        else
          raise HttpParserError501  , "#{TE_ERR_MSG}, unknown value: '#{te}'"
        end
      end

      @chunked_body = false

      cl = @env[CONTENT_LENGTH]

      if cl
        # cannot contain characters that are not \d, or be empty
        if CONTENT_LENGTH_VALUE_INVALID.match?(cl) || cl.empty?
          raise HttpParserError, "Invalid Content-Length: #{cl.inspect}"
        end
      else
        @buffer = body.empty? ? nil : body
        @body = EmptyBody
        set_ready
        return true
      end

      remain = cl.to_i - body.bytesize

      if remain <= 0
        @body = StringIO.new(body)
        @buffer = nil
        set_ready
        return true
      end

      if remain > MAX_BODY
        @body = Tempfile.new(Const::PUMA_TMP_BASE)
        @body.unlink
        @body.binmode
        @tempfile = @body
      else
        # The body[0,0] trick is to get an empty string in the same
        # encoding as body.
        @body = StringIO.new body[0,0]
      end

      @body.write body

      @body_remain = remain

      false
    end

    def read_body
      if @chunked_body
        return read_chunked_body
      end

      # Read an odd sized chunk so we can read even sized ones
      # after this
      remain = @body_remain

      if remain > CHUNK_SIZE
        want = CHUNK_SIZE
      else
        want = remain
      end

      begin
        chunk = @io.read_nonblock(want, @read_buffer)
      rescue IO::WaitReadable
        return false
      rescue SystemCallError, IOError
        raise ConnectionError, "Connection error detected during read"
      end

      # No chunk means a closed socket
      unless chunk
        @body.close
        @buffer = nil
        set_ready
        raise EOFError
      end

      remain -= @body.write(chunk)

      if remain <= 0
        @body.rewind
        @buffer = nil
        set_ready
        return true
      end

      @body_remain = remain

      false
    end

    def read_chunked_body
      while true
        begin
          chunk = @io.read_nonblock(4096, @read_buffer)
        rescue IO::WaitReadable
          return false
        rescue SystemCallError, IOError
          raise ConnectionError, "Connection error detected during read"
        end

        # No chunk means a closed socket
        unless chunk
          @body.close
          @buffer = nil
          set_ready
          raise EOFError
        end

        if decode_chunk(chunk)
          @env[CONTENT_LENGTH] = @chunked_content_length.to_s
          return true
        end
      end
    end

    def setup_chunked_body(body)
      @chunked_body = true
      @partial_part_left = 0
      @prev_chunk = ""
      @excess_cr = 0

      @body = Tempfile.new(Const::PUMA_TMP_BASE)
      @body.unlink
      @body.binmode
      @tempfile = @body
      @chunked_content_length = 0

      if decode_chunk(body)
        @env[CONTENT_LENGTH] = @chunked_content_length.to_s
        return true
      end
    end

    # @version 5.0.0
    def write_chunk(str)
      @chunked_content_length += @body.write(str)
    end

    def decode_chunk(chunk)
      if @partial_part_left > 0
        if @partial_part_left <= chunk.size
          if @partial_part_left > 2
            write_chunk(chunk[0..(@partial_part_left-3)]) # skip the \r\n
          end
          chunk = chunk[@partial_part_left..-1]
          @partial_part_left = 0
        else
          if @partial_part_left > 2
            if @partial_part_left == chunk.size + 1
              # Don't include the last \r
              write_chunk(chunk[0..(@partial_part_left-3)])
            else
              # don't include the last \r\n
              write_chunk(chunk)
            end
          end
          @partial_part_left -= chunk.size
          return false
        end
      end

      if @prev_chunk.empty?
        io = StringIO.new(chunk)
      else
        io = StringIO.new(@prev_chunk+chunk)
        @prev_chunk = ""
      end

      while !io.eof?
        line = io.gets
        if line.end_with?(CHUNK_VALID_ENDING)
          # Puma doesn't process chunk extensions, but should parse if they're
          # present, which is the reason for the semicolon regex
          chunk_hex = line.strip[/\A[^;]+/]
          if CHUNK_SIZE_INVALID.match? chunk_hex
            raise HttpParserError, "Invalid chunk size: '#{chunk_hex}'"
          end
          len = chunk_hex.to_i(16)
          if len == 0
            @in_last_chunk = true
            @body.rewind
            rest = io.read
            if rest.bytesize < CHUNK_VALID_ENDING_SIZE
              @buffer = nil
              @partial_part_left = CHUNK_VALID_ENDING_SIZE - rest.bytesize
              return false
            else
              # if the next character is a CRLF, set buffer to everything after that CRLF
              start_of_rest = if rest.start_with?(CHUNK_VALID_ENDING)
                CHUNK_VALID_ENDING_SIZE
              else # we have started a trailer section, which we do not support. skip it!
                rest.index(CHUNK_VALID_ENDING*2) + CHUNK_VALID_ENDING_SIZE*2
              end

              @buffer = rest[start_of_rest..-1]
              @buffer = nil if @buffer.empty?
              set_ready
              return true
            end
          end

          # Track the excess as a function of the size of the
          # header vs the size of the actual data. Excess can
          # go negative (and is expected to) when the body is
          # significant.
          # The additional of chunk_hex.size and 2 compensates
          # for a client sending 1 byte in a chunked body over
          # a long period of time, making sure that that client
          # isn't accidentally eventually punished.
          @excess_cr += (line.size - len - chunk_hex.size - 2)

          if @excess_cr >= MAX_CHUNK_EXCESS
            raise HttpParserError, "Maximum chunk excess detected"
          end

          len += 2

          part = io.read(len)

          unless part
            @partial_part_left = len
            next
          end

          got = part.size

          case
          when got == len
            # proper chunked segment must end with "\r\n"
            if part.end_with? CHUNK_VALID_ENDING
              write_chunk(part[0..-3]) # to skip the ending \r\n
            else
              raise HttpParserError, "Chunk size mismatch"
            end
          when got <= len - 2
            write_chunk(part)
            @partial_part_left = len - part.size
          when got == len - 1 # edge where we get just \r but not \n
            write_chunk(part[0..-2])
            @partial_part_left = len - part.size
          end
        else
          if @prev_chunk.size + chunk.size >= MAX_CHUNK_HEADER_SIZE
            raise HttpParserError, "maximum size of chunk header exceeded"
          end

          @prev_chunk = line
          return false
        end
      end

      if @in_last_chunk
        set_ready
        true
      else
        false
      end
    end

    def set_ready
      if @body_read_start
        @env['puma.request_body_wait'] = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - @body_read_start
      end
      @requests_served += 1
      @ready = true
    end

    def above_http_content_limit(value)
      @http_content_length_limit&.< value
    end
  end
end
