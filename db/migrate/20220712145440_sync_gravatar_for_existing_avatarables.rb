class SyncGravatarForExistingAvatarables < ActiveRecord::Migration[6.1]
  def change
    return if GlobalConfigService.load('DISABLE_GRAVATAR', '').present?

    sync_user_avatars
    sync_contact_avatars
  end

  private

  def sync_user_avatars
    ::User.find_in_batches do |users_batch|
      users_batch.each do |user|
        Avatar::AvatarFromGravatarJob.perform_later(user, user.email)
      end
    end
  end

  def sync_contact_avatars
    ::Contact.where.not(email: nil).find_in_batches do |contacts_batch|
      contacts_batch.each do |contact|
        Avatar::AvatarFromGravatarJob.perform_later(contact, contact.email)
      end
    end
  end
end
