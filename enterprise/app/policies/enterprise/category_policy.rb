module Enterprise::CategoryPolicy
  def index?
    @account_user.custom_role&.permissions&.include?('knowledge_base_manage') || super
  end

  def update?
    @account_user.custom_role&.permissions&.include?('knowledge_base_manage') || super
  end

  def show?
    @account_user.custom_role&.permissions&.include?('knowledge_base_manage') || super
  end

  def edit?
    @account_user.custom_role&.permissions&.include?('knowledge_base_manage') || super
  end

  def create?
    @account_user.custom_role&.permissions&.include?('knowledge_base_manage') || super
  end

  def destroy?
    @account_user.custom_role&.permissions&.include?('knowledge_base_manage') || super
  end
end
