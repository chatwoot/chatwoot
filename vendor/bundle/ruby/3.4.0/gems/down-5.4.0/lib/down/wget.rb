# frozen-string-literal: true

begin
  require "posix-spawn"
rescue LoadError
  require "open3"
end
require "http_parser"

require "down/backend"

require "tempfile"
require "uri"

module Down
  # Provides streaming downloads implemented with the wget command-line tool.
  # The design is very similar to Down::Http.
  class Wget < Backend
    # Initializes the backend with common defaults.
    def initialize(*arguments)
      @arguments = [
        user_agent:      "Down/#{Down::VERSION}",
        max_redirect:    2,
        dns_timeout:     30,
        connect_timeout: 30,
        read_timeout:    30,
      ] + arguments
    end

    # Downlods the remote file to disk. Accepts wget command-line options and
    # some additional options as well.
    def download(url, *args, max_size: nil, content_length_proc: nil, progress_proc: nil, destination: nil, extension: nil, **options)
      io = open(url, *args, **options, rewindable: false)

      content_length_proc.call(io.size) if content_length_proc && io.size

      if max_size && io.size && io.size > max_size
        raise Down::TooLarge, "file is too large (#{io.size/1024/1024}MB, max is #{max_size/1024/1024}MB)"
      end

      extname  = extension ? ".#{extension}" : File.extname(URI(url).path)
      tempfile = Tempfile.new(["down-wget", extname], binmode: true)

      until io.eof?
        chunk = io.readpartial(nil, buffer ||= String.new)

        tempfile.write(chunk)

        progress_proc.call(tempfile.size) if progress_proc

        if max_size && tempfile.size > max_size
          raise Down::TooLarge, "file is too large (#{tempfile.size/1024/1024}MB, max is #{max_size/1024/1024}MB)"
        end
      end

      tempfile.open # flush written content

      tempfile.extend Down::Wget::DownloadedFile
      tempfile.url     = url
      tempfile.headers = io.data[:headers]

      download_result(tempfile, destination)
    rescue
      tempfile.close! if tempfile
      raise
    ensure
      io.close if io
    end

    # Starts retrieving the remote file and returns an IO-like object which
    # downloads the response body on-demand. Accepts wget command-line options.
    def open(url, *args, rewindable: true, **options)
      arguments = generate_command(url, *args, **options)

      command = Down::Wget::Command.execute(arguments)
      # Wrap the wget command output in an IO-like object.
      output  = Down::ChunkedIO.new(
        chunks:     command.enum_for(:output),
        on_close:   command.method(:terminate),
        rewindable: false,
      )

      # https://github.com/tmm1/http_parser.rb/issues/29#issuecomment-309976363
      header_string  = output.readpartial
      header_string << output.readpartial until header_string.include?("\r\n\r\n")
      header_string, first_chunk = header_string.split("\r\n\r\n", 2)

      # Use an HTTP parser to parse out the response headers.
      parser = HTTP::Parser.new
      parser << header_string

      if parser.headers.nil?
        output.close
        raise Down::Error, "failed to parse response headers"
      end

      headers = normalize_headers(parser.headers)
      status  = parser.status_code

      content_length = headers["Content-Length"].to_i if headers["Content-Length"]
      charset        = headers["Content-Type"][/;\s*charset=([^;]+)/i, 1] if headers["Content-Type"]

      # Create an Enumerator which will lazily retrieve chunks of response body.
      chunks = Enumerator.new do |yielder|
        yielder << first_chunk if first_chunk
        yielder << output.readpartial until output.eof?
      end

      Down::ChunkedIO.new(
        chunks:     chunks,
        size:       content_length,
        encoding:   charset,
        rewindable: rewindable,
        on_close:   output.method(:close),
        data:       { status: status, headers: headers },
      )
    end

    private

    # Generates the wget command.
    def generate_command(url, *args, **options)
      command = %W[wget --no-verbose --save-headers -O -]

      options = @arguments.grep(Hash).inject({}, :merge).merge(options)
      args    = @arguments.grep(->(o){!o.is_a?(Hash)}) + args

      (args + options.to_a).each do |option, value|
        if option.is_a?(String)
          command << option
        elsif option.length == 1
          command << "-#{option}"
        else
          command << "--#{option.to_s.gsub("_", "-")}"
        end

        command << value.to_s unless value.nil?
      end

      command << url
      command
    end

    # Handles executing the wget command.
    class Command
      PIPE_BUFFER_SIZE = 64*1024

      def self.execute(arguments)
        # posix-spawn gem has better performance, so we use it if it's available
        if defined?(POSIX::Spawn)
          pid, stdin_pipe, stdout_pipe, stderr_pipe = POSIX::Spawn.popen4(*arguments)
          status_reaper = Process.detach(pid)
        else
          stdin_pipe, stdout_pipe, stderr_pipe, status_reaper = Open3.popen3(*arguments)
        end

        stdin_pipe.close
        [stdout_pipe, stderr_pipe].each(&:binmode)

        new(stdout_pipe, stderr_pipe, status_reaper)
      rescue Errno::ENOENT
        raise Down::Error, "wget is not installed"
      end

      def initialize(stdout_pipe, stderr_pipe, status_reaper)
        @status_reaper = status_reaper
        @stdout_pipe   = stdout_pipe
        @stderr_pipe   = stderr_pipe
      end

      # Yields chunks of stdout. At the end handles the exit status.
      def output
        # Keep emptying the stderr buffer, to allow the subprocess to send more
        # than 64KB if it wants to.
        stderr_reader = Thread.new { @stderr_pipe.read }

        yield @stdout_pipe.readpartial(PIPE_BUFFER_SIZE) until @stdout_pipe.eof?

        status = @status_reaper.value
        stderr = stderr_reader.value

        close

        handle_status(status, stderr)
      end

      def terminate
        begin
          Process.kill("TERM", @status_reaper[:pid])
          Process.waitpid(@status_reaper[:pid])
        rescue Errno::ESRCH
          # process has already terminated
        end

        close
      end

      def close
        @stdout_pipe.close unless @stdout_pipe.closed?
        @stderr_pipe.close unless @stderr_pipe.closed?
      end

      private

      # Translates nonzero wget exit statuses into exceptions.
      def handle_status(status, stderr)
        case status.exitstatus
        when 0  # No problems occurred
          # success
        when 1, # Generic error code
             2, # Parse error---for instance, when parsing command-line options, the .wgetrc or .netrc...
             3  # File I/O error
          raise Down::Error, stderr
        when 4  # Network failure
          raise Down::TimeoutError, stderr if stderr.include?("timed out")
          raise Down::ConnectionError, stderr
        when 5  # SSL verification failure
          raise Down::SSLError, stderr
        when 6  # Username/password authentication failure
          raise Down::ClientError, stderr
        when 7  # Protocol errors
          raise Down::Error, stderr
        when 8  # Server issued an error response
          raise Down::TooManyRedirects, stderr if stderr.include?("redirections exceeded")
          raise Down::ResponseError, stderr
        end
      end
    end

    # Adds additional attributes to the Tempfile returned in #download.
    module DownloadedFile
      attr_accessor :url, :headers

      def original_filename
        Utils.filename_from_content_disposition(headers["Content-Disposition"]) ||
        Utils.filename_from_path(URI.parse(url).path)
      end

      def content_type
        headers["Content-Type"].to_s.split(";").first
      end

      def charset
        headers["Content-Type"].to_s[/;\s*charset=([^;]+)/i, 1]
      end
    end
  end
end
