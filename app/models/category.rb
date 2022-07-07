# == Schema Information
#
# Table name: categories
#
#  id                 :bigint           not null, primary key
#  description        :text
#  locale             :string           default("en")
#  name               :string
#  position           :integer
#  slug               :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :integer          not null
#  linked_category_id :bigint
#  parent_category_id :bigint
#  portal_id          :integer          not null
#
# Indexes
#
#  index_categories_on_linked_category_id             (linked_category_id)
#  index_categories_on_locale                         (locale)
#  index_categories_on_locale_and_account_id          (locale,account_id)
#  index_categories_on_parent_category_id             (parent_category_id)
#  index_categories_on_slug_and_locale_and_portal_id  (slug,locale,portal_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (linked_category_id => categories.id)
#  fk_rails_...  (parent_category_id => categories.id)
#
class Category < ApplicationRecord
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
  has_many :linked_categories,
           class_name: :Category,
           foreign_key: :linked_category_id,
           dependent: :nullify,
           inverse_of: 'linked_category'
  belongs_to :parent_category, class_name: :Category, optional: true
  belongs_to :linked_category, class_name: :Category, optional: true

  before_validation :ensure_account_id
  validates :account_id, presence: true
  validates :slug, presence: true
  validates :name, presence: true
  validates :locale, uniqueness: { scope: %i[slug portal_id],
                                   message: 'should be unique in the category and portal' }
  accepts_nested_attributes_for :related_categories

  scope :search_by_locale, ->(locale) { where(locale: locale) if locale.present? }

  def self.search(params)
    search_by_locale(params[:locale]).page(current_page(params)).order(position: :asc)
  end

  def self.current_page(params)
    params[:page] || 1
  end

  private

  def ensure_account_id
    self.account_id = portal&.account_id
  end
end
