class Captain::EditorPolicy < ApplicationPolicy
  def process_event?
    true
  end
end
