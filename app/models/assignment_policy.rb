# frozen_string_literal: true

# == Schema Information
#
# Table name: assignment_policies
#
#  id                       :bigint           not null, primary key
#  assignment_order         :integer          default(0), not null
#  conversation_priority    :integer          default("earliest_created"), not null
#  description              :text
#  enabled                  :boolean          default(TRUE), not null
#  fair_distribution_limit  :integer          default(100), not null
#  fair_distribution_window :integer          default(3600), not null
#  name                     :string(255)      not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#
# Indexes
#
#  index_assignment_policies_on_account_id           (account_id)
#  index_assignment_policies_on_account_id_and_name  (account_id,name) UNIQUE
#  index_assignment_policies_on_enabled              (enabled)
#
class AssignmentPolicy < ApplicationRecord
  belongs_to :account
  has_many :inbox_assignment_policies, dependent: :destroy
  has_many :inboxes, through: :inbox_assignment_policies

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :fair_distribution_limit, numericality: { greater_than: 0 }
  validates :fair_distribution_window, numericality: { greater_than: 0 }

  enum conversation_priority: { earliest_created: 0, longest_waiting: 1 }

  # Default assignment order for community edition
  def assignment_order
    'round_robin'
  end

  def assignment_order=(_value)
    # Community edition only supports round_robin
    write_attribute(:assignment_order, 0)
  end
end

AssignmentPolicy.prepend_mod_with('AssignmentPolicy')
