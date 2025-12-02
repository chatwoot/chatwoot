class Captain::Tools::BaseService
  attr_reader :assistant, :user

  def initialize(assistant, user: nil)
    @assistant = assistant
    @user = user
  end

  def name
    raise NotImplementedError, "#{self.class.name} must implement #name"
  end

  def description
    raise NotImplementedError, "#{self.class.name} must implement #description"
  end

  def parameters
    raise NotImplementedError, "#{self.class.name} must implement #parameters"
  end

  def execute(args)
    raise NotImplementedError, "#{self.class.name} must implement #execute"
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

  protected

  def authorized_for?(permission_key)
    return false unless @user

    member = find_account_user
    return false unless member

    # Check custom role permissions if present
    return member.custom_role.permissions.include?(permission_key) if member.custom_role.present?

    # Default to admin/agent check
    member.administrator? || member.agent?
  end

  alias user_has_permission authorized_for?

  private

  def find_account_user
    AccountUser.find_by(account_id: @assistant.account_id, user_id: @user.id)
  end
end
