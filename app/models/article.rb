# == Schema Information
#
# Table name: articles
#
#  id                    :bigint           not null, primary key
#  content               :text
#  description           :text
#  status                :integer
#  title                 :string
#  views                 :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#  associated_article_id :bigint
#  author_id             :bigint
#  category_id           :integer
#  folder_id             :integer
#  portal_id             :integer          not null
#
# Indexes
#
#  index_articles_on_associated_article_id  (associated_article_id)
#  index_articles_on_author_id              (author_id)
#
# Foreign Keys
#
#  fk_rails_...  (associated_article_id => articles.id)
#  fk_rails_...  (author_id => users.id)
#
class Article < ApplicationRecord
  include PgSearch::Model

  has_many :associated_articles,
           class_name: :Article,
           foreign_key: :associated_article_id,
           dependent: :nullify,
           inverse_of: 'associated_article'

  belongs_to :associated_article, class_name: :Article, optional: true
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

  def associate_root_article(associated_article_id)
    article = portal.articles.find(associated_article_id) if associated_article_id.present?

    return if article.nil?

    root_articles_query = self.class.find_root_articles(article.id)
    root_articles = Article.find_by_sql(root_articles_query)
    
    return unless root_articles.any?

    root_article_id = root_articles.first.try(:associated_article_id)
    update(associated_article_id: root_article_id) if root_article_id.present?
  end

  # This will dig the articles record till we find the associated article is NULL
  def self.find_root_articles(current_article_id)
    <<-SQL.squish
      WITH RECURSIVE article_tree AS (
        SELECT articles.id, articles.id as associated_article_id
        FROM articles
        WHERE associated_article_id is NULL
      UNION
        SELECT referenced_articles.id, article_tree.associated_article_id
        FROM article_tree JOIN
          articles AS referenced_articles
          ON referenced_articles.associated_article_id = article_tree.id
      )
      SELECT article_tree.* FROM article_tree WHERE article_tree.id = #{current_article_id}
    SQL
  end

  private

  def ensure_account_id
    self.account_id = portal&.account_id
  end
end
