module ChatwootKanban
  # Authorization: a user can act on a board if they belong to the same Chatwoot account.
  # Administrators get full access; agents can read & move cards but not delete boards.
  class BoardPolicy < ::ApplicationPolicy
    def index?
      member_of_account?
    end

    def show?
      member_of_account?
    end

    def create?
      administrator?
    end

    def update?
      administrator?
    end

    def destroy?
      administrator?
    end

    def duplicate?
      administrator?
    end

    class Scope < ::ApplicationPolicy::Scope
      def resolve
        scope.where(account_id: account_id_from_context)
      end

      private

      def account_id_from_context
        @user.try(:account_id) || @user.try(:current_account_user)&.account_id
      end
    end

    private

    def member_of_account?
      return false unless @user && @record

      @user.accounts.exists?(id: @record.account_id)
    end

    def administrator?
      return false unless member_of_account?

      account_user = @user.account_users.find_by(account_id: @record.account_id)
      account_user&.administrator? || false
    end
  end
end
