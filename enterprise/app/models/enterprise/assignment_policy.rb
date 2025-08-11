module Enterprise::AssignmentPolicy
  # In enterprise, we extend the enum to include balanced
  # However, since Rails enums are frozen after definition,
  # we need to handle this differently

  # Override assignment_order= to accept 'balanced'
  def assignment_order=(value)
    if value.to_s == 'balanced'
      write_attribute(:assignment_order, 1)
    else
      super
    end
  end

  # Override assignment_order getter to return 'balanced' for value 1
  def assignment_order
    value = read_attribute(:assignment_order)
    return 'balanced' if value == 1

    super
  end

  # Define balanced? method
  def balanced?
    self[:assignment_order] == 1
  end
end
