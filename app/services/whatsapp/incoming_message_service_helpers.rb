module Whatsapp::IncomingMessageServiceHelpers
  def file_content_type(file_type)
    return :image if %w[image sticker].include?(file_type)
    return :audio if %w[audio voice].include?(file_type)
    return :video if ['video'].include?(file_type)
    return :location if ['location'].include?(file_type)

    :file
  end

  def unprocessable_message_type?(message_type)
    %w[reaction contacts ephemeral unsupported].include?(message_type)
  end
end
