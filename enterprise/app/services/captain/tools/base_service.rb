class Captain::Tools::BaseService
  attr_accessor :assistant

  def initialize(assistant, user: nil)
    @assistant = assistant
    @user = user
  end

  def name
    raise NotImplementedError, "#{self.class} must implement name"
  end

  def description
    raise NotImplementedError, "#{self.class} must implement description"
  end

  def parameters
    raise NotImplementedError, "#{self.class} must implement parameters"
  end

  def execute(arguments)
    raise NotImplementedError, "#{self.class} must implement execute"
  end

  def to_registry_format
    {
      type: 'function',
      function: {
        name: name,
        description: description,
        parameters: parameters
      }
    }
  end

  def active?
    true
  end

  private

  def user_has_permission(permission)
    return false if @user.blank?

    account_user = AccountUser.find_by(account_id: @assistant.account_id, user_id: @user.id)
    return false if account_user.blank?

    return account_user.custom_role.permissions.include?(permission) if account_user.custom_role.present?

    # Default permission for agents without custom roles
    account_user.administrator? || account_user.agent?
  end
end
