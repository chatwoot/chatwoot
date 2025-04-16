class Avatar::AvatarFromUrlJob < ApplicationJob
  queue_as :low

  def perform(avatarable, avatar_url)
    return unless avatarable.respond_to?(:avatar)
    return if avatar_url.blank?

    Rails.logger.info("Downloading avatar from URL: #{avatar_url} for #{avatarable.class.name} ##{avatarable.id}")

    begin
      avatar_file = Down.download(
        avatar_url,
        max_size: 15 * 1024 * 1024
      )

      if valid_image?(avatar_file)
        avatarable.avatar.attach(io: avatar_file, filename: avatar_file.original_filename,
                                 content_type: avatar_file.content_type)
        Rails.logger.info("Successfully attached avatar for #{avatarable.class.name} ##{avatarable.id}")
      else
        Rails.logger.warn("Invalid image file from URL: #{avatar_url}")
      end
    rescue Down::NotFound => e
      Rails.logger.error("Avatar not found at URL #{avatar_url}: #{e.message}")
      try_fallback_avatar(avatarable, avatar_url)
    rescue Down::Error => e
      Rails.logger.error("Error downloading avatar from URL #{avatar_url}: #{e.message}")
      try_fallback_avatar(avatarable, avatar_url)
    rescue StandardError => e
      Rails.logger.error("Unexpected error processing avatar from URL #{avatar_url}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
    end
  end

  private

  def valid_image?(file)
    return false if file.original_filename.blank?

    # TODO: check if the file is an actual image
    true
  end

  def try_fallback_avatar(avatarable, original_url)
    # Nếu URL là từ Facebook Graph API, thử lại với tham số khác
    if original_url.include?('graph.facebook.com') && original_url.include?('/picture')
      # Thử lại với type=normal thay vì type=large
      if original_url.include?('type=large')
        fallback_url = original_url.gsub('type=large', 'type=normal')
      else
        # Thêm tham số type=normal nếu chưa có
        fallback_url = original_url.include?('?') ? "#{original_url}&type=normal" : "#{original_url}?type=normal"
      end

      Rails.logger.info("Trying fallback Facebook avatar URL: #{fallback_url}")

      begin
        avatar_file = Down.download(
          fallback_url,
          max_size: 15 * 1024 * 1024
        )

        if valid_image?(avatar_file)
          avatarable.avatar.attach(io: avatar_file, filename: avatar_file.original_filename,
                                   content_type: avatar_file.content_type)
          Rails.logger.info("Successfully attached fallback avatar for #{avatarable.class.name} ##{avatarable.id}")
        end
      rescue => e
        Rails.logger.error("Failed to download fallback avatar: #{e.message}")
      end
    end
  end
end
