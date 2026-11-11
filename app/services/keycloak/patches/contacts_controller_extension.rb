# Users without can_view_all_contacts only see contacts reachable through their assigned inboxes.
# Every contact list (index, search, active, filter) goes through fetch_contacts*, and show/update/destroy
# through fetch_contact.
module Keycloak::Patches::ContactsControllerExtension
  private

  def fetch_contacts(contacts)
    super(keycloak_accessible_contacts(contacts))
  end

  def fetch_contacts_with_has_more(contacts)
    super(keycloak_accessible_contacts(contacts))
  end

  def fetch_contact
    super
    raise ActiveRecord::RecordNotFound unless keycloak_accessible_contacts(::Contact.where(id: @contact.id)).exists?
  end

  def keycloak_accessible_contacts(contacts)
    account_user = Current.account_user
    return contacts if account_user.nil? || account_user.has_permission?(:can_view_all_contacts)

    contacts.where(id: ::ContactInbox.where(inbox_id: Current.user.assigned_inboxes.select(:id)).select(:contact_id))
  end
end
