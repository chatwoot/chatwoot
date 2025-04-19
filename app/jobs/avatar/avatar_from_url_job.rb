class Avatar::AvatarFromUrlJob < ApplicationJob
  queue_as :low

  def perform(avatarable, avatar_url)
    Rails.logger.info "Avatar::AvatarFromUrlJob starting for #{avatarable.class.name} #{avatarable.id} with URL: #{avatar_url}"
    return unless avatarable.respond_to?(:avatar)

    begin
      # Make sure we have a valid URL (not nil or empty)
      if avatar_url.blank?
        Rails.logger.error "Avatar::AvatarFromUrlJob invalid URL - blank or nil"
        return
      end
      
      # Log the current avatar status
      if avatarable.avatar.attached?
        Rails.logger.info "Avatar::AvatarFromUrlJob found existing avatar attached"
      else
        Rails.logger.info "Avatar::AvatarFromUrlJob no existing avatar found"
      end
      
      Rails.logger.info "Avatar::AvatarFromUrlJob downloading image from URL: #{avatar_url}"
      
      avatar_file = Down.download(
        avatar_url,
        max_size: 15 * 1024 * 1024
      )
      
      if valid_image?(avatar_file)
        Rails.logger.info "Avatar::AvatarFromUrlJob downloaded image successfully, attaching to #{avatarable.class.name} #{avatarable.id}"
        Rails.logger.info "Avatar::AvatarFromUrlJob image details: type=#{avatar_file.content_type}, size=#{avatar_file.size}, name=#{avatar_file.original_filename}"
        
        # If there's an existing avatar, remove it first
        if avatarable.avatar.attached?
          Rails.logger.info "Avatar::AvatarFromUrlJob removing previous avatar"
          avatarable.avatar.purge
        end
        
        # Attach the new avatar
        avatarable.avatar.attach(io: avatar_file, filename: avatar_file.original_filename,
                               content_type: avatar_file.content_type)
                               
        # Verify the avatar was attached successfully
        if avatarable.avatar.attached?
          Rails.logger.info "Avatar::AvatarFromUrlJob successfully attached avatar"
        else
          Rails.logger.error "Avatar::AvatarFromUrlJob failed to attach avatar"
        end
      else
        Rails.logger.error "Avatar::AvatarFromUrlJob invalid image: #{avatar_file.original_filename}"
      end
    rescue Down::NotFound => e
      Rails.logger.error "Avatar::AvatarFromUrlJob - URL not found: #{avatar_url} : #{e.message}"
    rescue Down::Error => e
      Rails.logger.error "Avatar::AvatarFromUrlJob - error downloading: #{avatar_url} : #{e.message}"
    rescue => e
      Rails.logger.error "Avatar::AvatarFromUrlJob unexpected error: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  private

  def valid_image?(file)
    return false if file.nil? || file.original_filename.blank?

    # Basic validation of image file types
    valid_content_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    valid_extension = file.original_filename.downcase.end_with?('.jpg', '.jpeg', '.png', '.gif', '.webp')
    valid_content_type = valid_content_types.include?(file.content_type)
    
    Rails.logger.info "Avatar::AvatarFromUrlJob validating image: valid_extension=#{valid_extension}, valid_content_type=#{valid_content_type}, content_type=#{file.content_type}"
    
    valid_extension || valid_content_type
  end
end
