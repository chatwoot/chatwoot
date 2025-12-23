# == Schema Information
#
# Table name: labels
#
#  id              :bigint           not null, primary key
#  children_count  :integer
#  color           :string           default("#1f93ff"), not null
#  depth           :integer
#  description     :text
#  show_on_sidebar :boolean
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint
#  parent_id       :bigint
#
# Indexes
#
#  index_labels_on_account_id                (account_id)
#  index_labels_on_account_id_and_parent_id  (account_id,parent_id)
#  index_labels_on_parent_id                 (parent_id)
#  index_labels_on_title_and_account_id      (title,account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => labels.id)
#
class Label < ApplicationRecord
  include RegexHelper
  include AccountCacheRevalidator

  belongs_to :account
  belongs_to :parent, class_name: 'Label', optional: true, counter_cache: :children_count
  has_many :children, class_name: 'Label', foreign_key: 'parent_id', dependent: :destroy, inverse_of: :parent

  validates :title,
            presence: { message: I18n.t('errors.validations.presence') },
            format: { with: UNICODE_CHARACTER_NUMBER_HYPHEN_UNDERSCORE },
            uniqueness: { scope: :account_id }
  validate :prevent_circular_reference
  validate :prevent_deep_nesting
  validate :parent_belongs_to_same_account

  after_update_commit :update_associated_models
  before_save :calculate_depth
  default_scope { order(:title) }

  scope :root_labels, -> { where(parent_id: nil) }
  scope :with_children, -> { where('children_count > 0') }

  before_validation do
    self.title = title.downcase if attribute_present?('title')
  end

  def conversations
    account.conversations.tagged_with(title)
  end

  def messages
    account.messages.where(conversation_id: conversations.pluck(:id))
  end

  def reporting_events
    account.reporting_events.where(conversation_id: conversations.pluck(:id))
  end

  def aggregated_conversations
    label_titles = self_and_descendants.map(&:title)
    account.conversations.tagged_with(label_titles, any: true)
  end

  def aggregated_messages
    account.messages.where(conversation_id: aggregated_conversations.pluck(:id))
  end

  def aggregated_reporting_events
    account.reporting_events.where(conversation_id: aggregated_conversations.pluck(:id))
  end

  def descendants
    children.flat_map { |child| [child] + child.descendants }
  end

  def ancestors
    parent ? [parent] + parent.ancestors : []
  end

  def root?
    parent_id.nil?
  end

  def leaf?
    children_count.zero?
  end

  def depth
    read_attribute(:depth) || 0
  end

  def children_count
    read_attribute(:children_count) || 0
  end

  def self_and_descendants
    [self] + descendants
  end

  def self_and_ancestors
    [self] + ancestors
  end

  private

  def calculate_depth
    self[:depth] = parent ? parent.depth + 1 : 0
  end

  def prevent_circular_reference
    return if parent_id.blank?

    if parent_id == id
      errors.add(:parent_id, 'cannot be the same as the label')
    elsif ancestors.map(&:id).include?(id)
      errors.add(:parent_id, 'would create a circular reference')
    end
  end

  def prevent_deep_nesting
    max_depth = 5
    return if parent_id.blank?

    calculated_depth = parent ? (parent.depth + 1) : 0
    return unless calculated_depth > max_depth

    errors.add(:parent_id, "would exceed maximum nesting depth of #{max_depth}")
  end

  def parent_belongs_to_same_account
    return if parent_id.blank?
    return if parent&.account_id == account_id

    errors.add(:parent_id, 'must belong to the same account')
  end

  def update_associated_models
    return unless title_previously_changed?

    Labels::UpdateJob.perform_later(title, title_previously_was, account_id)
  end
end
