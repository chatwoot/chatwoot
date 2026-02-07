class AccountDeletionService
  SOFT_DELETE_EMAIL_SUFFIX = '-deleted.com'.freeze
  SOFT_DELETE_EMAIL_REGEX = /(?:-\d*deleted\.com)+\z/

  attr_reader :account, :soft_deleted_users

  def initialize(account:)
    @account = account
    @soft_deleted_users = []
  end

  def perform
    Rails.logger.info("Deleting account #{account.id} - #{account.name} that was marked for deletion")

    soft_delete_orphaned_users
    send_compliance_notification
    DeleteObjectJob.perform_later(account)
  end

  private

  def send_compliance_notification
    AdministratorNotifications::AccountComplianceMailer.with(
      account: account,
      soft_deleted_users: soft_deleted_users
    ).account_deleted(account).deliver_later
  end

  def soft_delete_orphaned_users
    account.users.each do |user|
      # Skip users who are still associated with another account.
      next if user.account_users.where.not(account_id: account.id).exists?

      original_email = user.email
      user.email = soft_deleted_email_for(user)
      user.skip_reconfirmation!
      user.save!

      user_info = {
        id: user.id.to_s,
        original_email: original_email
      }

      soft_deleted_users << user_info

      Rails.logger.info("Soft deleted user #{user.id} with email #{original_email}")
    end
  end

  def soft_deleted_email_for(user)
    original_email = normalized_email(user.email)
    attempt = 0

    loop do
      suffix = attempt.zero? ? SOFT_DELETE_EMAIL_SUFFIX : "-#{attempt}deleted.com"
      candidate = email_with_suffix(original_email, suffix)
      return candidate unless email_taken_by_other_user?(candidate, user.id)

      attempt += 1
    end
  end

  def normalized_email(email)
    email.to_s.sub(SOFT_DELETE_EMAIL_REGEX, '')
  end

  def email_with_suffix(email, suffix)
    email_limit = User.columns_hash['email']&.limit || 255
    max_email_length = email_limit - suffix.length
    local_part, domain = email.to_s.split('@', 2)

    if domain.blank?
      truncated_email = local_part.to_s.first(max_email_length)
      return "#{truncated_email}#{suffix}"
    end

    # Preserve @domain when truncating to stay within the column limit.
    max_domain_length = [max_email_length - 2, 1].max
    truncated_domain = domain.first(max_domain_length)
    max_local_length = [max_email_length - truncated_domain.length - 1, 1].max
    truncated_local = local_part.first(max_local_length)

    "#{truncated_local}@#{truncated_domain}#{suffix}"
  end

  def email_taken_by_other_user?(email, user_id)
    User.where.not(id: user_id).exists?(email: email)
  end
end
