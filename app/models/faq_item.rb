class FaqItem < ApplicationRecord
  belongs_to :account
  belongs_to :faq_category, optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  validate :has_at_least_one_translation

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
end
