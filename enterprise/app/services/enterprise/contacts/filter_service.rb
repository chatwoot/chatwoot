module Enterprise::Contacts::FilterService
  def base_relation
    relation = super
    return relation unless inbox_scoped_contacts?

    relation.joins(:contact_inboxes).where(contact_inboxes: { inbox_id: assigned_inbox_ids }).distinct
  end

  private

  def inbox_scoped_contacts?
    return false if account_user&.administrator?
    return false if account_user&.custom_role_permission?('contact_manage')

    account_user&.custom_role_permission?('contact_inbox_manage')
  end

  def account_user
    @account_user ||= @user.account_users.find_by(account: @account)
  end

  def assigned_inbox_ids
    @assigned_inbox_ids ||= @user.inboxes.where(account_id: @account.id).pluck(:id)
  end
end
