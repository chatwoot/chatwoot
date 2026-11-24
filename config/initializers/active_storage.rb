# Allow audio attachments (call recordings, voice notes) to serve inline so the
# in-app <audio> player can stream them. Without this, ActiveStorage's blob model
# forces Content-Disposition: attachment for any MIME outside the default allowlist
# (images + PDF), which makes the browser download instead of play.
Rails.application.config.active_storage.content_types_allowed_inline += %w[
  audio/webm
  audio/ogg
  audio/mpeg
  audio/mp4
  audio/x-m4a
  audio/wav
  audio/x-wav
]

# Rails blocks the libvips loaders for these formats. Keep the originals downloadable
# without generating representation URLs that fail when the thumbnail is processed.
Rails.application.config.active_storage.variable_content_types -= %w[
  image/bmp
  image/vnd.microsoft.icon
  image/vnd.adobe.photoshop
]

module ActiveStorageDirectUploadMetadataFilter
  INTERNAL_METADATA_KEYS = %w[identified analyzed composed].freeze

  private

  def blob_args
    super.tap do |args|
      args[:metadata]&.except!(*INTERNAL_METADATA_KEYS, *INTERNAL_METADATA_KEYS.map(&:to_sym))
    end
  end
end

module ActiveStorageProxyRangeLimit
  STREAMING_MAX_RANGES = 1
  STREAMING_CHUNK_MAX_SIZE = 100.megabytes

  private

  def send_blob_byte_range_data(blob, range_header, disposition: nil)
    ranges = Rack::Utils.get_byte_ranges(range_header, blob.byte_size)
    return head(:range_not_satisfiable) unless valid_ranges?(ranges)

    super
  end

  def valid_ranges?(ranges)
    ranges.present? &&
      ranges.any?(&:present?) &&
      ranges.length <= STREAMING_MAX_RANGES &&
      ranges.sum { |range| range.end - range.begin } < STREAMING_CHUNK_MAX_SIZE
  end
end

# Block the default Rails direct-upload route. Dashboard and widget uploads both go
# through the scoped, authenticated /api/v1/... endpoints, so the bare route has no
# legitimate caller; leaving it open allows anonymous blob creation. Scoped subclasses
# call super and are exempt via the instance_of? check.
module ActiveStorageBareDirectUploadGuard
  extend ActiveSupport::Concern

  included do
    before_action :reject_bare_direct_upload
  end

  private

  def reject_bare_direct_upload
    head :forbidden if instance_of?(ActiveStorage::DirectUploadsController)
  end
end

Rails.application.config.to_prepare do
  unless ActiveStorage::DirectUploadsController < ActiveStorageDirectUploadMetadataFilter
    ActiveStorage::DirectUploadsController.prepend(ActiveStorageDirectUploadMetadataFilter)
  end

  unless ActiveStorage::DirectUploadsController.include?(ActiveStorageBareDirectUploadGuard)
    ActiveStorage::DirectUploadsController.include(ActiveStorageBareDirectUploadGuard)
  end

  ActiveStorage::Streaming.prepend(ActiveStorageProxyRangeLimit) unless ActiveStorage::Streaming < ActiveStorageProxyRangeLimit
end

class ActiveStorageLegacyMessageReader
  class UnsupportedFormat < StandardError; end

  SCALARS = { '0' => nil, 'T' => true, 'F' => false }.freeze
  READERS = {
    'i' => :read_long, 'l' => :read_bignum, ':' => :read_symbol, ';' => :read_symbol_link,
    '"' => :read_string, 'I' => :read_encoded_string, '[' => :read_array, '{' => :read_hash
  }.freeze

  def self.load(dumped)
    new(dumped).read
  end

  def initialize(dumped)
    @bytes = dumped.b
    @position = 0
    @symbols = []
  end

  def read
    unsupported! unless read_bytes(2) == "\x04\b".b
    value = read_value
    unsupported! unless @position == @bytes.bytesize

    value
  end

  private

  def read_value
    type = read_byte.chr
    return SCALARS[type] if SCALARS.key?(type)

    send(READERS.fetch(type) { unsupported! })
  end

  def read_array
    Array.new(read_count) { read_value }
  end

  def read_hash
    Array.new(read_count) { [read_value, read_value] }.to_h
  end

  def read_string
    read_bytes(read_long)
  end

  def read_symbol_link
    @symbols.fetch(read_long) { unsupported! }
  end

  def read_symbol
    read_bytes(read_long).force_encoding(Encoding::UTF_8).to_sym.tap { |symbol| @symbols << symbol }
  end

  def read_encoded_string
    unsupported! unless read_byte.chr == '"'
    string = read_string
    read_count.times { string.force_encoding(encoding_for(read_value, read_value)) }
    string
  end

  def encoding_for(name, value)
    case name
    when :E then value == true ? Encoding::UTF_8 : Encoding::US_ASCII
    when :encoding then Encoding.find(value)
    else unsupported!
    end
  end

  def read_bignum
    sign = read_byte.chr
    unsupported! unless %w[+ -].include?(sign)
    value = little_endian(read_bytes(read_long * 2))
    sign == '-' ? -value : value
  end

  def read_long
    head = read_byte
    head -= 256 if head > 127
    return 0 if head.zero?
    return head - 5 if head > 4
    return head + 5 if head < -4

    value = little_endian(read_bytes(head.abs))
    head.positive? ? value : value - (1 << (8 * head.abs))
  end

  def read_count
    count = read_long
    unsupported! unless count.between?(0, @bytes.bytesize - @position)
    count
  end

  def little_endian(bytes)
    bytes.bytes.each_with_index.sum { |byte, index| byte << (8 * index) }
  end

  def read_byte
    read_bytes(1).ord
  end

  def read_bytes(length)
    unsupported! unless length.between?(0, @bytes.bytesize - @position)
    @bytes.byteslice(@position, length).tap { @position += length }
  end

  def unsupported!
    raise UnsupportedFormat, 'Unsupported message format'
  end
end

Rails.application.message_verifiers.rotate do |salt|
  { serializer: ActiveStorageLegacyMessageReader } if salt == 'ActiveStorage'
end
