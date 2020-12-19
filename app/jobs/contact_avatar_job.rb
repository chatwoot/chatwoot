class ContactAvatarJob < ApplicationJob
  queue_as :default

  def perform(contact, avatar_url)
    avatar_resource = LocalResource.new(avatar_url)
    contact.avatar.attach(io: avatar_resource.file, filename: avatar_resource.tmp_filename, content_type: avatar_resource.encoding)
  rescue *ExceptionList::URI_EXCEPTIONS, NoMethodError => e
    Rails.logger.info "Exception: invalid avatar url #{avatar_url} : #{e.message}"
  end
end
