module Enterprise::InboxPolicy
  def token?
    show?
  end

  def create?
    show?
  end

  def destroy?
    show?
  end
end
