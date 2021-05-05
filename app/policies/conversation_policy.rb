class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    accessible_inbox?
  end

  def mute?
    accessible_inbox?
  end

  def unmute?
    accessible_inbox?
  end

  def update_last_seen?
    accessible_inbox?
  end

  def toggle_status?
    accessible_inbox?
  end

  def toggle_typing_status?
    accessible_inbox?
  end

  def transcript?
    accessible_inbox?
  end

  private

  def accessible_inbox?
    Current.user.assigned_inboxes.include? record.inbox
  end
end
