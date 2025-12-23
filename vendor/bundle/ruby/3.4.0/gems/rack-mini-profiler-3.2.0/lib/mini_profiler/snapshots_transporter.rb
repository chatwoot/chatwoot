# frozen_string_literal: true

class ::Rack::MiniProfiler::SnapshotsTransporter
  @@transported_snapshots_count = 0
  @@successful_http_requests_count = 0
  @@failed_http_requests_count = 0

  class << self
    def transported_snapshots_count
      @@transported_snapshots_count
    end
    def successful_http_requests_count
      @@successful_http_requests_count
    end
    def failed_http_requests_count
      @@failed_http_requests_count
    end

    def transport(snapshot)
      @transporter ||= self.new(Rack::MiniProfiler.config)
      @transporter.ship(snapshot)
    end
  end

  attr_reader :buffer
  attr_accessor :max_buffer_size, :gzip_requests

  def initialize(config)
    @uri = URI(config.snapshots_transport_destination_url)
    @auth_key = config.snapshots_transport_auth_key
    @gzip_requests = config.snapshots_transport_gzip_requests
    @thread = nil
    @thread_mutex = Mutex.new
    @buffer = []
    @buffer_mutex = Mutex.new
    @max_buffer_size = 100
    @consecutive_failures_count = 0
    @testing = false
  end

  def ship(snapshot)
    @buffer_mutex.synchronize do
      @buffer << snapshot
      @buffer.shift if @buffer.size > @max_buffer_size
    end
    @thread_mutex.synchronize { start_thread }
  end

  def flush_buffer
    buffer_content = @buffer_mutex.synchronize do
      @buffer.dup if @buffer.size > 0
    end
    if buffer_content
      headers = {
        'Content-Type' => 'application/json',
        'Mini-Profiler-Transport-Auth' => @auth_key
      }
      json = { snapshots: buffer_content }.to_json
      body = if @gzip_requests
        require 'zlib'
        io = StringIO.new
        gzip_writer = Zlib::GzipWriter.new(io)
        gzip_writer.write(json)
        gzip_writer.close
        headers['Content-Encoding'] = 'gzip'
        io.string
      else
        json
      end
      request = Net::HTTP::Post.new(@uri, headers)
      request.body = body
      http = Net::HTTP.new(@uri.hostname, @uri.port)
      http.use_ssl = @uri.scheme == 'https'
      res = http.request(request)
      if res.code.to_i == 200
        @@successful_http_requests_count += 1
        @@transported_snapshots_count += buffer_content.size
        @buffer_mutex.synchronize do
          @buffer -= buffer_content
        end
        @consecutive_failures_count = 0
      else
        @@failed_http_requests_count += 1
        @consecutive_failures_count += 1
      end
    end
  end

  def requests_interval
    [30 + backoff_delay, 60 * 60].min
  end

  private

  def backoff_delay
    return 0 if @consecutive_failures_count == 0
    2**@consecutive_failures_count
  end

  def start_thread
    return if @thread&.alive? || @testing
    @thread = Thread.new do
      while true
        sleep requests_interval
        flush_buffer
      end
    end
  end
end
