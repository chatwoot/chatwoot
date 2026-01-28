# frozen_string_literal: true

# Tool for sending an image or file attachment in the response
# LLM calls this with a URL and the attachment is downloaded and included in the message
#
# Example usage in agent:
#   chat.with_tools([SendAttachmentTool])
#   response = chat.ask("Send this image: https://example.com/image.jpg")
#
class SendAttachmentTool < BaseTool
  description 'Attach an image or file to your response message. ' \
              'Use this when you want to show the customer an image directly in the chat. ' \
              'Pass the URL of the image you want to attach.'

  param :url, type: :string, desc: 'The URL of the image or file to attach', required: true

  def execute(url:)
    validate_context!
    validate_url!(url)

    success_response(
      queued: true,
      url: url,
      message: 'Attachment will be included in your response'
    )
  rescue ArgumentError => e
    error_response(e.message)
  rescue StandardError => e
    error_response("Failed to queue attachment: #{e.message}")
  end

  private

  def validate_url!(url)
    uri = URI.parse(url)
    raise ArgumentError, 'Invalid URL: must be HTTP or HTTPS' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    raise ArgumentError, 'Invalid URL format'
  end
end
