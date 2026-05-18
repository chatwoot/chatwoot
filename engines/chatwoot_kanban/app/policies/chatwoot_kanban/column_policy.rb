module ChatwootKanban
  class ColumnPolicy < ::ApplicationPolicy
    def index?      = same_account?
    def show?       = same_account?
    def create?     = administrator?
    def update?     = administrator?
    def destroy?    = administrator?
    def reorder?    = same_account?

    private

    def same_account?
      account_id = @record.respond_to?(:board) ? @record.board&.account_id : @record.first&.board&.account_id
      account_id && @user.accounts.exists?(id: account_id)
    end

    def administrator?
      return false unless @record.respond_to?(:board) && @record.board

      au = @user.account_users.find_by(account_id: @record.board.account_id)
      au&.administrator? || false
    end
  end
end
