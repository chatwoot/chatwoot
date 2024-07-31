module Enterprise::AccountUser
  def permissions
    (custom_role&.permissions.presence || super) + ['custom_role']
  end
end
