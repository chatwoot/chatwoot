require 'open3'

# Transcodes inbound Ogg/Opus (and WebM) voice notes to MP3 so Safari on macOS and iOS can play
# them; Safari has no Ogg support. See chatwoot/chatwoot#10286 and #13210.
#
# Returns { transcoded: true, io:, filename:, content_type: } on success, or { transcoded: false }
# for non-transcodable input, a missing ffmpeg binary or any ffmpeg failure. Failures are reported
# and swallowed so the caller keeps the original file.
class Audio::TranscoderService
  class TranscodeError < StandardError; end

  TRANSCODABLE_MIME = %w[audio/ogg audio/opus audio/x-opus+ogg audio/vorbis audio/webm application/ogg].freeze
  TRANSCODABLE_EXT = %w[.ogg .oga .opus .weba .webm].freeze
  OUTPUT_CONTENT_TYPE = 'audio/mpeg'.freeze
  TIMEOUT_SECONDS = 120

  def self.ffmpeg_available?
    return @ffmpeg_available unless @ffmpeg_available.nil?

    @ffmpeg_available = system('ffmpeg', '-version', out: File::NULL, err: File::NULL) ? true : false
    Rails.logger.warn('[Audio::TranscoderService] ffmpeg not found in PATH; inbound audio is stored as received.') unless @ffmpeg_available
    @ffmpeg_available
  end

  def initialize(io:, filename:, content_type:)
    @io = io
    @filename = filename.to_s
    @content_type = content_type.to_s.split(';').first.to_s.strip.downcase
  end

  def perform
    return { transcoded: false } unless transcodable? && self.class.ffmpeg_available?

    { transcoded: true, io: StringIO.new(transcode), filename: mp3_filename, content_type: OUTPUT_CONTENT_TYPE }
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    { transcoded: false }
  ensure
    rewind_source
  end

  def transcodable?
    return true if TRANSCODABLE_MIME.include?(@content_type)

    TRANSCODABLE_EXT.include?(File.extname(@filename).downcase)
  end

  private

  def transcode
    Dir.mktmpdir('cw-audio') do |dir|
      source_path = File.join(dir, "source#{File.extname(@filename).presence || '.ogg'}")
      output_path = File.join(dir, 'output.mp3')
      write_source(source_path)
      run_ffmpeg(source_path, output_path)
      raise TranscodeError, 'ffmpeg produced an empty file' unless File.size?(output_path)

      File.binread(output_path)
    end
  end

  def write_source(path)
    rewind_source
    File.open(path, 'wb') { |file| IO.copy_stream(@io, file) }
    raise TranscodeError, 'source audio is empty' unless File.size?(path)
  end

  # The input is untrusted: pin the demuxer and allow only local file access, so a playlist or
  # other format disguised as Ogg cannot make ffmpeg read other files or fetch URLs.
  # Mono 64 kbps MP3 is plenty for voice and keeps files close to the Opus original in size.
  def ffmpeg_command(source_path, output_path)
    ['ffmpeg', '-nostdin', '-hide_banner', '-loglevel', 'error', '-y',
     '-protocol_whitelist', 'file', '-f', input_format, '-i', source_path,
     '-vn', '-map_metadata', '-1', '-ac', '1', '-c:a', 'libmp3lame', '-b:a', '64k', output_path]
  end

  def input_format
    webm = @content_type == 'audio/webm' || %w[.weba .webm].include?(File.extname(@filename).downcase)
    webm ? 'matroska' : 'ogg'
  end

  def run_ffmpeg(source_path, output_path)
    Open3.popen3(*ffmpeg_command(source_path, output_path)) do |stdin, stdout, stderr, wait_thread|
      stdin.close
      readers = [Thread.new { stdout.read }, Thread.new { stderr.read }]
      timed_out = wait_thread.join(TIMEOUT_SECONDS).nil?
      kill(wait_thread.pid) if timed_out
      # Drain both pipes before popen3 closes them, so the reader threads finish cleanly.
      error_output = readers.map(&:value).last.to_s
      raise TranscodeError, "ffmpeg timed out after #{TIMEOUT_SECONDS}s" if timed_out
      raise TranscodeError, "ffmpeg exited with #{wait_thread.value.exitstatus}: #{error_output.last(500)}" unless wait_thread.value.success?
    end
  end

  def kill(pid)
    Process.kill('KILL', pid)
  rescue Errno::ESRCH
    nil
  end

  def rewind_source
    @io.rewind if @io.respond_to?(:rewind)
  rescue IOError
    nil
  end

  def mp3_filename
    "#{File.basename(@filename.presence || 'audio', '.*').presence || 'audio'}.mp3"
  end
end
