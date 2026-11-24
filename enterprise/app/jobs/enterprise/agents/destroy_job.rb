module Enterprise::Agents::DestroyJob
  private

  def unassign_conversations(account, user)
    super
    return unless ::SearchIndexing::Conversations.enabled?(account)

    ActiveRecord.after_all_transactions_commit do
      ::SearchIndexing::AssociationRefreshJob.perform_later('assignee_id', user.id, account.id)
    end
  end
end
