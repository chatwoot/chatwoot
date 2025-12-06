module Enterprise::InboxPolicy
  def conference_token?
    show?
  end

  def conference_join?
    show?
  end

  def conference_leave?
    show?
  end
end
