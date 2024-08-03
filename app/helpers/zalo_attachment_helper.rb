module ZaloAttachmentHelper
  include ::FileTypeHelper
  attr_accessor :params, :message

  def file_content_type(media)
    return :image if %w[image gif sticker].include?(media[:type])
    return :audio if media[:type] == 'audio'
    return :video if media[:type] == 'video'

    file_type(media[:payload][:type])
  end

  def attach_media # rubocop:disable Metrics/AbcSize
    return if params[:message][:attachments].blank?

    params[:message][:attachments].each do |media|
      case media[:type]
      when 'link'
        message.content = "Link: #{media[:payload][:url]}"
      when 'location'
        attach_location(media)
      else
        # File size bigger than 10Mb will show as link
        if media[:type] == 'file' && media[:payload][:size].to_i > 10 * 1024 * 1024
          message.content = "File to download: #{media[:payload][:url]}"
          next
        end

        attach_file(media)
      end
    end
  end

  def attach_location(media)
    message.attachments.new(
      account_id: message.account_id,
      file_type: :location,
      coordinates_lat: media[:payload][:coordinates][:latitude],
      coordinates_long: media[:payload][:coordinates][:longitude]
    )
  end

  def attach_file(media)
    attachment_file = Down.download(media[:payload][:url])
    file_name = media[:payload][:name] || attachment_file.original_filename
    message.attachments.new(
      account_id: message.account_id,
      file_type: file_content_type(media),
      file: {
        io: attachment_file,
        filename: file_name,
        content_type: attachment_file.content_type
      }
    )
    message.content_type = 'sticker' if media[:type] == 'sticker'
  end
end
