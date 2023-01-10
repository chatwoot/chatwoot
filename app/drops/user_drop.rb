class UserDrop < BaseDrop
  def available_name
    @obj.try(:available_name)
  end

  def first_name
    @obj.try(:name).try(:split).try(:first)
  end

  def last_name
    @obj.try(:name).try(:split).try(:last) if @obj.try(:name).try(:split).try(:size) > 1
  end
end
