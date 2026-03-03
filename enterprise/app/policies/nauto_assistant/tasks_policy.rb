class NautoAssistant::TasksPolicy < ApplicationPolicy
  def rewrite? = true
  def summarize? = true
  def reply_suggestion? = true
  def label_suggestion? = true
  def follow_up? = true
end
