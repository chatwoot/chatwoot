class DataImportPolicy < ApplicationPolicy
  def index?
    contact_import?
  end

  def show?
    record.account_id == account.id && (record.data_type == 'contacts' ? contact_import? : integration_import?)
  end

  def create?
    record.is_a?(DataImport) ? show? : contact_import?
  end

  def validate_source?
    create?
  end

  def start?
    show?
  end

  def retry_import?
    show?
  end

  def abandon?
    show?
  end

  def skip_logs?
    show?
  end

  def error_logs?
    show?
  end

  def rejected_rows?
    show?
  end

  def contact_import?
    ContactPolicy.new(user_context, Contact).import?
  end

  def integration_import?
    account_user.administrator? && account.feature_enabled?('data_import')
  end

  class Scope < Scope
    def resolve
      imports = scope.where(account_id: account.id)
      return imports if account_user.administrator? && account.feature_enabled?('data_import')
      return imports.where(data_type: 'contacts') if ContactPolicy.new(user_context, Contact).import?

      scope.none
    end
  end
end
