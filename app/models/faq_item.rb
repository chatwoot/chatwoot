class FaqItem < ApplicationRecord
  include Events::Types

  belongs_to :account
  belongs_to :faq_category, optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  validate :has_at_least_one_translation

  # Skip callbacks for bulk operations (handled separately in controllers)
  attr_accessor :skip_catalog_callbacks

  after_create_commit :dispatch_create_event, unless: :skip_catalog_callbacks
  after_update_commit :dispatch_update_event, unless: :skip_catalog_callbacks
  after_destroy_commit :dispatch_destroy_event, unless: :skip_catalog_callbacks

  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  scope :visible, -> { where(is_visible: true) }
  scope :for_category, ->(category_id) { where(faq_category_id: category_id) }

  # Helper methods for translations
  def question(locale = 'es')
    translations.dig(locale.to_s, 'question') || translations.dig('en', 'question')
  end

  def answer(locale = 'es')
    translations.dig(locale.to_s, 'answer') || translations.dig('en', 'answer')
  end

  def available_locales
    translations.keys
  end

  private

  def has_at_least_one_translation
    return if translations.present? && translations.values.any? { |t| t['question'].present? }

    errors.add(:translations, 'must have at least one question')
  end

  def faq_item_payload
    { id: id, faq_category_id: faq_category_id }
  end

  def dispatch_faq_event(target_account:, added: 0, updated: 0, deleted: 0, added_items: [], updated_items: [], deleted_items: [])
    Rails.configuration.dispatcher.dispatch(
      FAQ_CATALOG_UPDATED,
      Time.zone.now,
      account: target_account,
      added_count: added,
      updated_count: updated,
      deleted_count: deleted,
      added_faq_items: added_items,
      updated_faq_items: updated_items,
      deleted_faq_items: deleted_items
    )
  end

  def dispatch_create_event
    dispatch_faq_event(target_account: account, added: 1, added_items: [faq_item_payload])
  end

  def dispatch_update_event
    dispatch_faq_event(target_account: account, updated: 1, updated_items: [faq_item_payload])
  end

  def dispatch_destroy_event
    dispatch_faq_event(target_account: account, deleted: 1, deleted_items: [faq_item_payload])
  end
end
