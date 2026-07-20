class AccountDrop < BaseDrop
  def name
    @obj.try(:name)
  end

  def locale
    @obj.try(:locale)
  end

  def timezone
    @obj.try(:timezone)
  end
end
