module Enterprise::Agents::DestroyJob
  private

  def unassign_account_owners(account, user)
    super

    # rubocop:disable Rails/SkipsModelValidations
    user.owned_companies.where(account: account).in_batches.update_all(account_owner_id: nil)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
