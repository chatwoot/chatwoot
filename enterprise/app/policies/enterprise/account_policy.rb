module Enterprise::AccountPolicy
  def billing_summary?
    @account_user.administrator?
  end
end
