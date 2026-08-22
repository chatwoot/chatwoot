class ZaloOa::MessageSender
  class WindowError < StandardError; end
  class RetryableError < StandardError; end
  class PermanentError < StandardError; end

  MESSAGE_URL = 'https://openapi.zalo.me/v3.0/oa/message/cs'.freeze
  IMAGE_UPLOAD_URL = 'https://openapi.zalo.me/v2.0/oa/upload/image'.freeze
  FILE_UPLOAD_URL = 'https://openapi.zalo.me/v2.0/oa/upload/file'.freeze

  IMAGE_EXTENSIONS = %w[jpg jpeg png gif webp].freeze
  # GIF is excluded: re-encoding it would drop the animation. An oversized GIF is uploaded
  # as-is and, like any image Zalo still rejects, fails with a PermanentError that surfaces
  # to the agent as a failed message.
  COMPRESSIBLE_EXTENSIONS = %w[jpg jpeg png webp].freeze
  # Compress before upload when the source exceeds this; also the compression target.
  # Conservative margin under Zalo OA's ~1MB image cap.
  IMAGE_COMPRESS_THRESHOLD = 900_000
  RETRYABLE_CODES = [-32, -100].freeze
  # Not followed, blocked invite, banned/inactive, no interaction, expired interaction,
  # night curfew (22h-6h), user restricted this message type.
  WINDOW_CODES = [-213, -217, -227, -230, -232, -234, -244].freeze

  pattr_initialize [:channel!]

  def send_text(user_id, text, quoted_message_id = nil)
    body = { recipient: { user_id: user_id }, message: { text: text }.compact }
    body[:message][:quote_message_id] = quoted_message_id if quoted_message_id.present?
    post_message(body)
  rescue PermanentError
    raise if quoted_message_id.blank?

    # An unusable quote id (bad param) is a PermanentError, not a rate limit or transient failure, so
    # only this case is worth retrying without the quote. RetryableError propagates to Sidekiq as-is:
    # resending immediately without the quote would double our request rate exactly when Zalo is
    # throttling us, and would needlessly drop the quote for a failure that had nothing to do with it.
    post_message({ recipient: { user_id: user_id }, message: { text: text } })
  end

  def send_attachment(user_id, attachment, caption)
    image?(attachment) ? send_image(user_id, attachment, caption) : send_file(user_id, attachment, caption)
  end

  private

  def image?(attachment)
    IMAGE_EXTENSIONS.include?(extension(attachment))
  end

  def extension(attachment)
    attachment.file.filename.extension.to_s.downcase
  end

  def send_image(user_id, attachment, caption)
    attachment_id = upload(IMAGE_UPLOAD_URL, image_tempfile_path(attachment), 'attachment_id')
    post_message(
      recipient: { user_id: user_id },
      message: {
        text: caption.presence,
        attachment: {
          type: 'template',
          payload: { template_type: 'media', elements: [{ media_type: 'image', attachment_id: attachment_id }] }
        }
      }.compact
    )
  end

  def send_file(user_id, attachment, caption)
    token = upload(FILE_UPLOAD_URL, save_attachment_to_tempfile(attachment), 'token')
    post_message(
      recipient: { user_id: user_id },
      message: { text: caption.presence, attachment: { type: 'file', payload: { token: token } } }.compact
    )
  end

  def upload(url, temp_file_path, id_field)
    File.open(temp_file_path, 'rb') do |file|
      response = HTTParty.post(url, headers: { 'access_token' => channel.valid_access_token }, body: { file: file })
      id = response.parsed_response.dig('data', id_field)
      raise PermanentError, "upload rejected: #{response.parsed_response['error']} #{response.parsed_response['message']}".strip if id.blank?

      id.to_s
    end
  ensure
    File.delete(temp_file_path) if temp_file_path && File.exist?(temp_file_path)
  end

  # Shrinks the image first when it's over Zalo's cap and re-encodable (see ImageCompressor).
  # Falls back to the original file, unchanged, when compression isn't applicable or doesn't
  # find a fit under the target — the upload then either succeeds anyway or is rejected by
  # Zalo, in which case the agent sees a failed message rather than a silently dropped one.
  def image_tempfile_path(attachment)
    original_path = save_attachment_to_tempfile(attachment)
    return original_path unless compressible?(attachment)

    compressed = ZaloOa::ImageCompressor.new(path: original_path).call
    return original_path if compressed.nil?

    File.delete(original_path)
    write_tempfile(attachment, "compressed.#{compressed[:ext]}") { |file| file.write(compressed[:data]) }
  end

  def compressible?(attachment)
    COMPRESSIBLE_EXTENSIONS.include?(extension(attachment)) && attachment.file.blob.byte_size > IMAGE_COMPRESS_THRESHOLD
  end

  # Streams the blob to disk instead of loading it into memory. Always removed by the
  # `ensure` in `upload`, on both a successful and a failed send.
  def save_attachment_to_tempfile(attachment)
    write_tempfile(attachment, attachment.file.filename.to_s) do |file|
      attachment.file.blob.open { |blob_file| IO.copy_stream(blob_file, file) }
    end
  end

  def write_tempfile(attachment, filename, &)
    temp_dir = Rails.root.join('tmp/uploads', "zalo-oa-#{attachment.id}")
    FileUtils.mkdir_p(temp_dir)
    temp_file_path = File.join(temp_dir, filename)
    File.open(temp_file_path, 'wb', &)
    temp_file_path
  end

  def post_message(body)
    response = HTTParty.post(
      MESSAGE_URL,
      headers: { 'access_token' => channel.valid_access_token, 'Content-Type' => 'application/json' },
      body: body.to_json
    )
    parse_response(response.parsed_response)
  end

  def parse_response(body)
    code = body['error'].to_i
    return body.dig('data', 'message_id').to_s if code.zero?

    detail = "Zalo OA send failed: #{code} #{body['message']}".strip
    raise RetryableError, detail if RETRYABLE_CODES.include?(code)
    raise WindowError, detail if WINDOW_CODES.include?(code)

    raise PermanentError, detail
  end
end
