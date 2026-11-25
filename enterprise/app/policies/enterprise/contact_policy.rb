module Enterprise::ContactPolicy
  def export?
    @account_user.custom_role&.permissions&.include?('contact_manage') || super
  end

  def import?
    @account_user.custom_role&.permissions&.include?('contact_manage') || super
  end
end
