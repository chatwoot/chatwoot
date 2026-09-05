module Enterprise::AccountUser
  def permissions
    custom_role.present? ? (custom_role.permissions + ['custom_role']) : super
  end

  def custom_role_permission?(*names)
    return false if custom_role.blank?

    (custom_role.permissions & names.flatten.map(&:to_s)).any?
  end
end
