# frozen_string_literal: true

class ScheduledMessagePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    # Agents e administrators podem criar mensagens agendadas
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    # Owner ou administrator pode editar
    owner? || @account_user.administrator?
  end

  def destroy?
    # Owner ou administrator pode cancelar
    owner? || @account_user.administrator?
  end

  def send_now?
    # Owner ou administrator pode enviar imediatamente
    owner? || @account_user.administrator?
  end

  private

  def owner?
    @record.sender_id == @user.id
  end

  class Scope < Scope
    def resolve
      # Retorna apenas mensagens da conta atual
      scope.where(account_id: @account.id)
    end
  end
end
