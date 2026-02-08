class AgentBotPresenter < SimpleDelegator
  def access_token
    return if account_id.blank?

    Current.account.id == account_id ? super&.token : nil
  end
end
