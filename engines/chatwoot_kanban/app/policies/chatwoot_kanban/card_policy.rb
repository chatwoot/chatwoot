module ChatwootKanban
  # Agents can read/move/edit cards inside their account; only administrators can delete.
  class CardPolicy < ::ApplicationPolicy
    def index?   = same_account?
    def show?    = same_account?
    def create?  = same_account?
    def update?  = same_account?
    def move?    = same_account?
    def destroy? = administrator?

    private

    def same_account?
      return false unless @user && @record

      account_id = @record.respond_to?(:account_id) ? @record.account_id : nil
      account_id ||= @record.try(:board)&.account_id
      account_id && @user.accounts.exists?(id: account_id)
    end

    def administrator?
      return false unless @record && @record.try(:board)

      au = @user.account_users.find_by(account_id: @record.board.account_id)
      au&.administrator? || false
    end
  end
end
