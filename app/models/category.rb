# == Schema Information
#
# Table name: categories
#
#  id                     :bigint           not null, primary key
#  description            :text
#  icon                   :string           default("")
#  locale                 :string           default("en")
#  name                   :string
#  position               :integer
#  slug                   :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :integer          not null
#  associated_category_id :bigint
#  parent_category_id     :bigint
#  portal_id              :integer          not null
#
# Indexes
#
#  index_categories_on_associated_category_id         (associated_category_id)
#  index_categories_on_locale                         (locale)
#  index_categories_on_locale_and_account_id          (locale,account_id)
#  index_categories_on_parent_category_id             (parent_category_id)
#  index_categories_on_slug_and_locale_and_portal_id  (slug,locale,portal_id) UNIQUE
#
class Category < ApplicationRecord
  paginates_per Limits::CATEGORIES_PER_PAGE
  belongs_to :account
  belongs_to :portal
  has_many :folders, dependent: :destroy_async
  has_many :articles, dependent: :nullify
  has_many :category_related_categories,
           class_name: :RelatedCategory,
           dependent: :destroy_async
  has_many :related_categories,
           through: :category_related_categories,
           class_name: :Category,
           dependent: :nullify
  has_many :sub_categories,
           class_name: :Category,
           foreign_key: :parent_category_id,
           dependent: :nullify,
           inverse_of: 'parent_category'
  has_many :associated_categories,
           class_name: :Category,
           foreign_key: :associated_category_id,
           dependent: :nullify,
           inverse_of: 'root_category'
  belongs_to :parent_category, class_name: :Category, optional: true
  belongs_to :root_category,
             class_name: :Category,
             foreign_key: :associated_category_id,
             inverse_of: :associated_categories,
             optional: true

  before_validation :ensure_account_id
  before_validation :associate_with_root_category, if: :will_save_change_to_associated_category_id?
  validates :account_id, presence: true
  validates :slug, presence: true
  validates :name, presence: true
  validate :allowed_locales
  validates :locale, uniqueness: { scope: %i[slug portal_id],
                                   message: I18n.t('errors.categories.locale.unique') }
  validate :cannot_reassociate_translation_family, if: -> { persisted? && will_save_change_to_associated_category_id? }
  validate :unique_locale_in_translation_family, if: -> { errors[:locale].empty? }
  accepts_nested_attributes_for :related_categories

  scope :search_by_locale, ->(locale) { where(locale: locale) if locale.present? }

  def self.search(params)
    search_by_locale(params[:locale]).page(current_page(params)).order(position: :asc)
  end

  def self.current_page(params)
    params[:page] || 1
  end

  def self.find_root_category_id(category)
    current_category = category
    visited_ids = []

    while current_category.associated_category_id.present? && visited_ids.exclude?(current_category.id)
      visited_ids << current_category.id
      root_category = current_category.root_category
      break if root_category.nil?

      current_category = root_category
    end

    current_category.id
  end

  def self.update_positions(portal:, positions_hash:)
    return if positions_hash.blank?

    transaction do
      positions_hash.each do |category_id, new_position|
        portal.categories.find(category_id).update!(position: new_position)
      end
    end
  end

  private

  def associate_with_root_category
    category = portal&.categories&.find_by(id: associated_category_id)
    self.associated_category_id = self.class.find_root_category_id(category) if category
  end

  def unique_locale_in_translation_family
    root_id = translation_family_root_id
    return if root_id.blank? || locale.blank?

    root_id = lock_translation_family_roots(root_id)
    self.associated_category_id = root_id if associated_category_id.present?
    matching_categories = portal.categories.where(id: translation_family_ids(root_id), locale: locale)
    matching_categories = matching_categories.where.not(id: id)
    errors.add(:locale, :taken) if matching_categories.exists?
  end

  def cannot_reassociate_translation_family = (errors.add(:associated_category_id, :invalid) if associated_categories.exists?)

  def lock_translation_family_roots(root_id)
    root_ids = [root_id]

    if persisted? && will_save_change_to_associated_category_id?
      previous_parent_id = associated_category_id_in_database
      previous_root_id = previous_parent_id ? self.class.find_root_category_id(portal.categories.find(previous_parent_id)) : id
      root_ids << previous_root_id
    end

    portal.categories.where(id: root_ids.compact.uniq.sort).order(:id).lock.load
    translation_family_root_id.tap { |current_root_id| portal.categories.lock.find(current_root_id) }
  end

  def translation_family_root_id
    return id if associated_category_id.blank?

    self.class.uncached { self.class.find_root_category_id(portal.categories.find(associated_category_id)) }
  end

  def translation_family_ids(root_id)
    category_ids = [root_id]
    parent_ids = [root_id]

    while (parent_ids = portal.categories.where(associated_category_id: parent_ids).where.not(id: category_ids).pluck(:id)).any?
      category_ids.concat(parent_ids)
    end

    category_ids
  end

  def ensure_account_id
    self.account_id = portal&.account_id
  end

  def allowed_locales
    return if portal.blank?

    allowed_locales = portal.allowed_locale_codes

    return true if allowed_locales.include?(locale)

    errors.add(:locale, "#{locale} of category is not part of portal's #{allowed_locales}.")
  end
end
