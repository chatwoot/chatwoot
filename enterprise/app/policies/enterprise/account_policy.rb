module Enterprise::AccountPolicy
  def reconnect_shopify?
    @account_user.administrator?
  end

  def billing_summary?
    @account_user.administrator?
  end
end
