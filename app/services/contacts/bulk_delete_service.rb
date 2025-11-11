class Contacts::BulkDeleteService
  def initialize(account:, contact_ids: [])
    @account = account
    @contact_ids = Array(contact_ids).compact
  end

  def perform
    return if @contact_ids.blank?

    contacts.find_each(&:destroy!)
  end

  private

  def contacts
    @account.contacts.where(id: @contact_ids)
  end
end
