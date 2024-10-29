class AccountDrop < BaseDrop
  def name
    @obj.try(:name)
  end
end
