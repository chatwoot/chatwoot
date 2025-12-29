class FaqCategory < ApplicationRecord
  belongs_to :account
  belongs_to :parent, class_name: 'FaqCategory', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  has_many :children, class_name: 'FaqCategory', foreign_key: :parent_id, dependent: :destroy
  has_many :faq_items, dependent: :destroy
  has_many :inbox_faq_categories, dependent: :destroy
  has_many :inboxes, through: :inbox_faq_categories

  validates :name, presence: true

  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  scope :visible, -> { where(is_visible: true) }

  # Validate max depth of 2 levels
  validate :validate_max_depth

  private

  def validate_max_depth
    return unless parent_id.present?

    if parent&.parent_id.present?
      errors.add(:parent_id, 'cannot have more than 2 levels of nesting')
    end
  end
end
