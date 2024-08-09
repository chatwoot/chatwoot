# == Schema Information
#
# Table name: tickets
#
#  id              :bigint           not null, primary key
#  assigned_to     :bigint
#  description     :text
#  resolved_at     :datetime
#  status          :integer          default("pending"), not null
#  title           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_tickets_on_account_id       (account_id)
#  index_tickets_on_assigned_to      (assigned_to)
#  index_tickets_on_conversation_id  (conversation_id)
#  index_tickets_on_status           (status)
#  index_tickets_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (user_id => users.id)
#
class Ticket < ApplicationRecord
  belongs_to :user, inverse_of: :tickets
  belongs_to :conversation, inverse_of: :tickets
  belongs_to :assignee, class_name: 'User', foreign_key: 'assigned_to', optional: true, inverse_of: :assigned_tickets
  belongs_to :account, inverse_of: :tickets

  has_many :label_tickets, inverse_of: :ticket, dependent: :destroy
  has_many :labels, through: :label_tickets

  enum status: { pending: 0, in_progress: 1, resolved: 2 }

  validates :title, presence: true
  validates :status, inclusion: { in: statuses.keys }

  before_save :set_resolved_at

  scope :resolved, -> { where(status: :resolved) }
  scope :unresolved, -> { where(status: :pending) }
  scope :with_agents_ids, lambda { |agent_ids|
    where(assigned_to: agent_ids) if agent_ids.present?
  }

  scope :assigned_to, ->(user_id) { where(assigned_to: user_id).or(where(assigned_to: nil)) }

  def resolution_time
    return nil unless resolved_at

    resolved_at - created_at
  end

  def self.search(params)
    if params[:search].present?
      where('LOWER(title) LIKE ? OR LOWER(description) LIKE ?', "%#{query.downcase}%", "%#{query.downcase}%")
    elsif params[:label].present?
      joins(:labels).where(labels: { title: params[:label] })
    else
      all
    end
  end

  private

  def set_resolved_at
    self.resolved_at = Time.current if status_changed? && resolved?
  end
end
