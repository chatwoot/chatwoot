module Enterprise::PortalPolicy
  def index?
    super || @account_user.custom_role&.permissions&.include?('knowledge_base_manage')
  end

  def update?
    super || @account_user.custom_role&.permissions&.include?('knowledge_base_manage')
  end

  def show?
    super || @account_user.custom_role&.permissions&.include?('knowledge_base_manage')
  end

  def edit?
    super || @account_user.custom_role&.permissions&.include?('knowledge_base_manage')
  end

  def create?
    super || @account_user.custom_role&.permissions&.include?('knowledge_base_manage')
  end

  def destroy?
    super || @account_user.custom_role&.permissions&.include?('knowledge_base_manage')
  end

  def add_members?
    super || @account_user.custom_role&.permissions&.include?('knowledge_base_manage')
  end

  def logo?
    super || @account_user.custom_role&.permissions&.include?('knowledge_base_manage')
  end
end
