class KanbanColumnPolicy < ApplicationPolicy
  def index?
    record.kanban_board.user_id == user.id
  end

  def create?
    record.kanban_board.user_id == user.id
  end

  def update?
    record.kanban_board.user_id == user.id
  end

  def destroy?
    record.kanban_board.user_id == user.id
  end
end
