module Enterprise::AssignmentPolicy
  def assignment_order=(value)
    if value.to_s == 'balanced'
      write_attribute(:assignment_order, 1)
    else
      super
    end
  end

  def assignment_order
    value = read_attribute(:assignment_order)
    return 'balanced' if value == 1

    super
  end

  def balanced?
    self[:assignment_order] == 1
  end
end
