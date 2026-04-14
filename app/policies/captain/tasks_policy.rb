class Captain::TasksPolicy < ApplicationPolicy
  def rewrite?
    true
  end

  def summarize?
    true
  end

  def reply_suggestion?
    true
  end

  def label_suggestion?
    true
  end

  def follow_up?
    true
  end
end
