class SlaPolicyDrop < BaseDrop
  def name
    @obj.try(:name)
  end

  def description
    @obj.try(:description)
  end
end
