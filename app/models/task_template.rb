class TaskTemplate < ApplicationRecord
  PRIORITIES = %w[normal high urgent].freeze

  belongs_to :account
  belongs_to :default_team, class_name: 'Team', optional: true
  has_many :internal_tasks, dependent: :nullify

  validates :key, presence: true, uniqueness: { scope: :account_id }
  validates :title, presence: true
  validates :default_priority, inclusion: { in: PRIORITIES }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }
end
