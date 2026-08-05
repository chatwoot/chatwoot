class Captain::FaqSuggestionPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def update?
    true
  end

  def approve?
    true
  end

  def dismiss?
    true
  end
end
