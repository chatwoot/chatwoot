# frozen_string_literal: true

# Resolves attachments from tool calls by downloading files from URLs
#
# Used by ResponseService to process SendAttachmentTool calls and download images
# that will be attached to the outgoing message.
#
# Example:
#   tool_calls = [{'name' => 'send_attachment', 'arguments' => {'url' => 'https://example.com/image.jpg'}}]
#   resolver = Aloo::AttachmentResolver.new(tool_calls)
#   attachments = resolver.resolve  # Returns array of ActionDispatch::Http::UploadedFile objects
#
class Aloo::AttachmentResolver
  def initialize(tool_calls)
    @tool_calls = tool_calls || []
  end

  def resolve
    @tool_calls.filter_map { |tool_call| resolve_tool_call(tool_call) }
  end

  private

  def resolve_tool_call(tool_call)
    name = tool_call['name'] || tool_call[:name]
    return nil unless name == 'send_attachment'

    arguments = tool_call['arguments'] || tool_call[:arguments] || {}
    url = arguments['url'] || arguments[:url]

    download_attachment(url)
  end

  def download_attachment(url)
    return nil if url.blank?

    file = Down.download(url, max_size: 10.megabytes)

    ActionDispatch::Http::UploadedFile.new(
      tempfile: file,
      filename: file.original_filename || extract_filename(url),
      type: file.content_type
    )
  rescue Down::Error => e
    Rails.logger.error "[ALOO] Failed to download attachment from #{url}: #{e.message}"
    nil
  end

  def extract_filename(url)
    uri = URI.parse(url)
    File.basename(uri.path).presence || 'attachment'
  rescue URI::InvalidURIError
    'attachment'
  end
end
