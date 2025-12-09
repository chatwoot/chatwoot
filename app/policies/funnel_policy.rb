class FunnelPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    true
  end

  def destroy?
    true
  end

  # Permissão para mover contatos entre colunas do funil (drag and drop)
  def move_contact?
    true
  end
end
