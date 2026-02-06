class FaqCategory < ApplicationRecord
  include Events::Types

  # Limits
  MAX_CATEGORIES_PER_ACCOUNT = 250

  belongs_to :account
  belongs_to :parent, class_name: 'FaqCategory', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  has_many :children, class_name: 'FaqCategory', foreign_key: :parent_id, dependent: :destroy
  has_many :faq_items, dependent: nil # Handled manually to send bulk webhook
  has_many :inbox_faq_categories, dependent: :destroy
  has_many :inboxes, through: :inbox_faq_categories

  validates :name, presence: true

  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  scope :visible, -> { where(is_visible: true) }

  # Validate max depth of 2 levels
  validate :validate_max_depth
  validate :validate_categories_per_account_limit, on: :create

  before_destroy :destroy_faq_items_with_skip_callbacks
  after_destroy_commit :dispatch_bulk_faq_deleted_event

  private

  def validate_max_depth
    return unless parent_id.present?

    if parent&.parent_id.present?
      errors.add(:parent_id, 'cannot have more than 2 levels of nesting')
    end
  end

  def validate_categories_per_account_limit
    return if account_id.blank?

    current_count = FaqCategory.where(account_id: account_id).count
    return unless current_count >= MAX_CATEGORIES_PER_ACCOUNT

    errors.add(:account, "already has #{MAX_CATEGORIES_PER_ACCOUNT} categories (maximum limit)")
  end

  def destroy_faq_items_with_skip_callbacks
    @cached_deleted_faq_items = faq_items.pluck(:id, :faq_category_id).map do |item_id, cat_id|
      { id: item_id, faq_category_id: cat_id }
    end
    @cached_account = account

    faq_items.find_each do |item|
      item.skip_catalog_callbacks = true
      item.destroy
    end
  end

  def dispatch_bulk_faq_deleted_event
    return if @cached_deleted_faq_items.blank?

    Rails.configuration.dispatcher.dispatch(
      FAQ_CATALOG_UPDATED,
      Time.zone.now,
      account: @cached_account,
      added_count: 0,
      updated_count: 0,
      deleted_count: @cached_deleted_faq_items.size,
      added_faq_items: [],
      updated_faq_items: [],
      deleted_faq_items: @cached_deleted_faq_items
    )
  end
end
