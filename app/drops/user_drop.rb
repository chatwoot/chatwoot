class UserDrop < BaseDrop
  def available_name
    @obj.try(:available_name)
  end
end
