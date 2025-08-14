module Enterprise::AssignmentPolicy
  ASSIGNMENT_ORDERS = {
    'round_robin' => 0,
    'balanced' => 1
  }.freeze

  def assignment_order
    ASSIGNMENT_ORDERS.key(read_attribute(:assignment_order)) || 'round_robin'
  end

  def assignment_order=(value)
    order_value = ASSIGNMENT_ORDERS[value] || 0
    write_attribute(:assignment_order, order_value)
  end
end
