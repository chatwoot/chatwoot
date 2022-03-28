class ContactAvatarJob < ApplicationJob
  queue_as :default

  def perform(contact, avatar_url)
    avatar_file = Down.download(
      avatar_url,
      max_size: 15 * 1024 * 1024
    )
    contact.avatar.attach(io: avatar_file, filename: avatar_file.original_filename, content_type: avatar_file.content_type)
  rescue Down::Error => e
    Rails.logger.error "Exception: invalid avatar url #{avatar_url} : #{e.message}"
  end
end
