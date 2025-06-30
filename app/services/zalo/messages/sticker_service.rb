class Zalo::Messages::StickerService < Zalo::Messages::BaseService

  private

  def content_type
    :sticker
  end

  def content_attributes
    super.merge(
      original: {
        image_url: params.dig(:message, :attachments, 0, :payload, :url),
      }
    )
  end
end
