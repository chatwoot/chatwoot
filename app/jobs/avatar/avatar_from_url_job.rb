class Avatar::AvatarFromUrlJob < ApplicationJob
  queue_as :low

  def perform(avatarable, avatar_url)
    return unless avatarable.respond_to?(:avatar)

    avatar_file = Down.download(
      avatar_url,
      max_size: 15 * 1024 * 1024
    )
    avatarable.avatar.attach(io: avatar_file, filename: avatar_file.original_filename, content_type: avatar_file.content_type)
  rescue Down::NotFound, Down::Error => e
    Rails.logger.error "Exception: invalid avatar url #{avatar_url} : #{e.message}"
  end
end
