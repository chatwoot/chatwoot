class UserDrop < BaseDrop
  def name
    @obj.try(:name).try(:split).try(:map, &:capitalize).try(:join, ' ')
  end

  def available_name
    @obj.try(:available_name)
  end

  def email
    @obj.try(:email)
  end

  def first_name
    @obj.try(:name).try(:split).try(:first).try(:capitalize)
  end

  # Returns the capitalized last name extracted from the user's full name.
  #
  # The full name is split on whitespace and the final segment is
  # capitalized. If the name has only one word (no separate last name)
  # or is blank, this returns nil.
  #
  # @return [String, nil] the user's last name, or nil if unavailable
  def last_name
    @obj.try(:name).try(:split).try(:last).try(:capitalize) if @obj.try(:name).try(:split).try(:size).to_i > 1
  end
end
