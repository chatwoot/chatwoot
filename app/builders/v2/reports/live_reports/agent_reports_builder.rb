class V2::LiveReports::AgentReportsBuilder
  pattr_initialize :account, :params
  AGENT_RESULTS_PER_PAGE = 25

  def build
    account_users = account.account_users.page(params[:page]).per(AGENT_RESULTS_PER_PAGE)
    account_users.each_with_object([]) do |account_user, arr|
      user = account_user.user
      arr << {
        id: user.id,
        name: user.name,
        email: user.email,
        thumbnail: user.avatar_url,
        availability: account_user.availability_status,
        metric: live_conversations(user)
      }
    end
  end

  private

  def live_conversations(user)
    open_conversations = user.conversations.where(account_id: @account.id).open
    {
      open: open_conversations.count,
      unattended: open_conversations.unattended.count
    }
  end
end
