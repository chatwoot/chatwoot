# == Schema Information
#
# Table name: articles
#
#  id                :bigint           not null, primary key
#  content           :text
#  description       :text
#  status            :integer
#  title             :string
#  views             :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :integer          not null
#  author_id         :bigint
#  category_id       :integer
#  folder_id         :integer
#  linked_article_id :bigint
#  portal_id         :integer          not null
#
# Indexes
#
#  index_articles_on_author_id          (author_id)
#  index_articles_on_linked_article_id  (linked_article_id)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (linked_article_id => articles.id)
#
class Article < ApplicationRecord
  include PgSearch::Model

  has_many :linked_articles,
           class_name: :Article,
           foreign_key: :linked_article_id,
           dependent: :nullify,
           inverse_of: 'linked_article'

  belongs_to :linked_article, class_name: :Article, optional: true
  belongs_to :account
  belongs_to :category
  belongs_to :portal
  belongs_to :author, class_name: 'User'

  before_validation :ensure_account_id
  validates :account_id, presence: true
  validates :category_id, presence: true
  validates :author_id, presence: true
  validates :title, presence: true
  validates :content, presence: true

  enum status: { draft: 0, published: 1 }

  scope :search_by_category_slug, ->(category_slug) { where(categories: { slug: category_slug }) if category_slug.present? }
  scope :search_by_category_locale, ->(locale) { where(categories: { locale: locale }) if locale.present? }

  # TODO: if text search slows down https://www.postgresql.org/docs/current/textsearch-features.html#TEXTSEARCH-UPDATE-TRIGGERS
  pg_search_scope(
    :text_search,
    against: %i[
      title
      description
      content
    ],
    using: {
      tsearch: {
        prefix: true
      }
    }
  )

  def self.search(params)
    records = joins(
      :category
    ).search_by_category_slug(params[:category_slug]).search_by_category_locale(params[:locale])
    records.text_search(params[:query]) if params[:query].present?
    records.page(current_page(params))
  end

  def self.current_page(params)
    params[:page] || 1
  end

  def link_root_article(linked_article_id)
    article = portal.articles.find(linked_article_id) if linked_article_id.present?

    return if article.nil?

    root_article_id = self.class.find_root_article_id(article)

    update(linked_article_id: root_article_id) if root_article_id.present?
  end

  # Mkes sure we always associate the parent's associated id to avoid the deeper associations od articles.
  def self.find_root_article_id(article)
    article.linked_article.try(:id) || article.id
  end

  private

  def ensure_account_id
    self.account_id = portal&.account_id
  end
end
