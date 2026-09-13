class Captain::Apropos::Access
  def self.check!(account, user)
    membership = account.account_users.find_by(user_id: user.id)
    raise Captain::Apropos::Error, 'Apropos requires an account administrator' unless membership&.administrator?
    raise Captain::Apropos::Error, 'Captain is not enabled for this account' unless account.feature_enabled?('captain_integration')
  end
end
