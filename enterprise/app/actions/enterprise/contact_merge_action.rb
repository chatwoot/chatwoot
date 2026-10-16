module Enterprise::ContactMergeAction
  private

  def merge_calls
    Call.where(account_id: @account.id, contact_id: @mergee_contact.id).update(contact_id: @base_contact.id)
  end
end
