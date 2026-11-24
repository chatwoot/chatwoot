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

module ActiveStorageLegacySignedIdReader
  extend self

  FIXNUM = 'i'.ord
  BIGNUM = 'l'.ord

  def load(dumped)
    bytes = dumped.b.bytes
    value = read_integer(bytes) if bytes.shift(2) == [4, 8]
    raise ArgumentError, 'Unsupported message format' unless value&.positive? && bytes.empty?

    value
  end

  private

  def read_integer(bytes)
    case bytes.shift
    when FIXNUM then read_long(bytes)
    when BIGNUM then read_bignum(bytes)
    end
  end

  def read_long(bytes)
    head = bytes.shift.to_i
    return head - 5 if head.between?(6, 127)

    little_endian(bytes.shift(head)) if head.between?(1, 4) && bytes.size >= head
  end

  def read_bignum(bytes)
    return unless bytes.shift == '+'.ord

    shorts = read_long(bytes)
    little_endian(bytes.shift(shorts * 2)) if shorts && bytes.size >= shorts * 2
  end

  def little_endian(bytes)
    bytes.each_with_index.sum { |byte, index| byte << (8 * index) }
  end
end

Rails.application.message_verifiers.rotate do |salt|
  { serializer: ActiveStorageLegacySignedIdReader } if salt == 'ActiveStorage'
end
