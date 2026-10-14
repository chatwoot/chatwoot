module Enterprise::CompanyPolicy
  def enrich?
    @account_user.administrator?
  end
end
