# frozen_string_literal: true

class Enterprise::AgentCapacityPolicy < ApplicationRecord
  self.table_name = 'agent_capacity_policies'

  belongs_to :account, class_name: '::Account'
  has_many :inbox_capacity_limits, class_name: 'Enterprise::InboxCapacityLimit', dependent: :destroy
  has_many :inboxes, through: :inbox_capacity_limits, class_name: '::Inbox'
  has_many :account_users, class_name: '::AccountUser', dependent: :nullify

  validates :name, presence: true, length: { maximum: 255 }

  def applicable_for_time?(time = Time.current)
    return true if exclusion_rules.blank?

    !excluded_for_time?(time)
  end

  def capacity_for_inbox(inbox)
    inbox_capacity_limits.find_by(inbox: inbox)&.conversation_limit
  end

  def overall_capacity
    exclusion_rules['overall_capacity'] || Float::INFINITY
  end

  private

  def excluded_for_time?(time)
    excluded_by_hours?(time) || excluded_by_days?(time)
  end

  def excluded_by_hours?(time)
    return false if exclusion_rules['hours'].blank?

    current_hour = time.hour
    exclusion_rules['hours'].include?(current_hour)
  end

  def excluded_by_days?(time)
    return false if exclusion_rules['days'].blank?

    current_day = time.strftime('%A').downcase
    exclusion_rules['days'].include?(current_day)
  end
end
