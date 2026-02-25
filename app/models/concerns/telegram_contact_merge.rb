module TelegramContactMerge
  extend ActiveSupport::Concern

  included do
    alias_method :original_update, :update

    def update
      original_update
      attempt_telegram_contact_merge
    end
  end

  private

  def attempt_telegram_contact_merge
    return unless telegram_contact?(@contact)

    project, source_email = project_and_email(@contact)
    return unless project && source_email

    account = Current.account
    inbox_ids = inbox_ids_for_project(account, project)
    return if inbox_ids.blank?

    target = find_target_contact(account, inbox_ids, source_email)
    return unless target

    merge_contacts(target, @contact)
  rescue StandardError => e
    Rails.logger.error "[TG MERGE] ERROR: #{e.class} #{e.message}\n#{e.backtrace.first(5).join("\n")}"
  end

  def project_and_email(contact)
    project      = contact.custom_attributes&.dig('project').to_s.downcase.strip
    email        = contact.custom_attributes&.dig('user_email').to_s.downcase.strip
    [project.presence, email.presence]
  end

  def inbox_ids_for_project(account, project)
    ids = account.inboxes.where('LOWER(name) LIKE ?', "%#{project}%").pluck(:id)
    Rails.logger.info "[TG MERGE] Project inboxes #{ids}"
    ids
  end

  def find_target_contact(account, inbox_ids, source_email)
    account.contacts
           .joins(:contact_inboxes)
           .where(contact_inboxes: { inbox_id: inbox_ids })
           .where.not(id: @contact.id)
           .where(
             "LOWER(contacts.email) = :email OR LOWER(custom_attributes->>'user_email') = :email",
             email: source_email
           )
           .first.tap do |t|
             Rails.logger.info t ? "[TG MERGE] Found target #{t.id}" : '[TG MERGE] No target found'
           end
  end

  def merge_contacts(base_contact, mergee_contact)
    Rails.logger.info "[TG MERGE] Merging #{mergee_contact.id} -> #{base_contact.id}"
    ContactMergeAction.new(
      account: Current.account,
      base_contact: base_contact,
      mergee_contact: mergee_contact
    ).perform
    Rails.logger.info '[TG MERGE] Done'
  end

  def telegram_contact?(contact)
    contact.contact_inboxes.joins(:inbox)
           .exists?(inboxes: { channel_type: 'Channel::Telegram' })
  end
end
