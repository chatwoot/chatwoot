module Enterprise::AccountUser
  def permissions
    custom_role&.permissions.presence || super
  end
end
