# frozen_string_literal: true

class Captain::Tools::BaseAgentTool < Agents::Tool
  def initialize(assistant, user: nil)
    @assistant = assistant
    @user = user
    super()
  end

  def active?
    user_has_permission(required_permission)
  end

  protected

  def required_permission
    # Override in subclasses to specify the required permission
    'agent'
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

  def account_scoped(model_class)
    model_class.where(account_id: @assistant.account_id)
  end

  def log_tool_usage(action, details = {})
    Rails.logger.info do
      "#{self.class.name}: #{action} by user #{@user&.id} for assistant #{@assistant&.id} - #{details.inspect}"
    end
  end
end
