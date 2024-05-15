class V2::Reports::LiveReports::AccountReportsBuilder
  pattr_initialize :account

  def build
    open_conversations = account.conversations.open
    metric = {
      open: open_conversations.count,
      unattended: open_conversations.unattended.count
    }
    metric[:unassigned] = open_conversations.unassigned.count
    metric[:pending] = open_conversations.pending.count
    metric
  end
end
