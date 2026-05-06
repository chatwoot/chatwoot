module MailboxContactInboxHelper
  private

  def find_or_create_contact_inbox
    @contact_inbox = ContactInbox.find_by(inbox: @inbox, contact: @contact) || ContactInboxBuilder.new(
      contact: @contact,
      inbox: @inbox,
      source_id: processed_mail.original_sender
    ).perform
  end
end
