class AccountDrop < Liquid::Drop
  def initialize(account)
    @account = account
  end

  def name
    @account.name
  end
end
