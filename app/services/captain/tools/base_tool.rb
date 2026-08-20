class Captain::Tools::BaseTool < RubyLLM::Tool
  prepend Captain::Tools::Instrumentation

  attr_accessor :assistant

  def initialize(assistant, user: nil)
    @assistant = assistant
    @user = user
    super()
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

    account_user.administrator? || account_user.agent?
  end
end
