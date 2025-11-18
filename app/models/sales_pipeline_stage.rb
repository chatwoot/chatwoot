class SalesPipelineStage < ApplicationRecord
  belongs_to :account
  belongs_to :sales_pipeline
  belongs_to :label

  validates :name, presence: true
  validates :position, presence: true, uniqueness: { scope: [:account_id, :sales_pipeline_id] }
  validates :label_id, uniqueness: { scope: :account_id }
  validate :at_most_one_default_stage
  validate :mutually_exclusive_closed_flags

  before_validation :sync_with_label
  after_update :sync_label_changes
  after_destroy :cleanup_label

  scope :ordered, -> { order(:position) }
  scope :default_stage, -> { where(is_default: true) }
  scope :closed_won, -> { where(is_closed_won: true) }
  scope :closed_lost, -> { where(is_closed_lost: true) }
  scope :active_stages, -> { where(is_closed_won: false, is_closed_lost: false) }

  default_scope { ordered }

  def conversations
    account.conversations.tagged_with(label.title)
  end

  def self.for_label(label_title, account)
    joins(:label).where(labels: { title: label_title }, account: account).first
  end

  private

  def sync_with_label
    return unless label.present?

    self.name = label.title if name.blank?
    self.color = label.color if color.blank?
  end

  def sync_label_changes
    return unless saved_changes.key?(:name) || saved_changes.key?(:color)

    label.update!(
      title: name,
      color: color
    )
  end

  def cleanup_label
    return unless label.present?

    label.destroy if label.conversations.empty?
  end

  def at_most_one_default_stage
    return unless is_default?
    return unless account_id.present?

    existing_default = SalesPipelineStage.where(
      account_id: account_id,
      is_default: true
    ).where.not(id: id).exists?

    errors.add(:is_default, 'já existe um estágio padrão para esta conta') if existing_default
  end

  def mutually_exclusive_closed_flags
    if is_closed_won? && is_closed_lost?
      errors.add(:is_closed_lost, 'não pode ser marcado como ganho e perdido ao mesmo tempo')
    end
  end
end