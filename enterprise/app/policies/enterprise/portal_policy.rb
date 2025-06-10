module Enterprise::PortalPolicy
  def update?
    @account_user.custom_role&.permissions&.include?('knowledge_base_manage') || super
  end

  def edit?
    @account_user.custom_role&.permissions&.include?('knowledge_base_manage') || super
  end

  def logo?
    @account_user.custom_role&.permissions&.include?('knowledge_base_manage') || super
  end
end
