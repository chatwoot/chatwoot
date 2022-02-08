class InboxDrop < BaseDrop
  def name
    @obj.try(:name)
  end
end
