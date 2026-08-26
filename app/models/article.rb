# == Schema Information
#
# Table name: articles
#
#  id                    :bigint           not null, primary key
#  content               :text
#  description           :text
#  draft_content         :text
#  draft_title           :string
#  locale                :string           default("en"), not null
#  meta                  :jsonb
#  position              :integer
#  slug                  :string           not null
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
#  index_articles_on_account_id             (account_id)
#  index_articles_on_associated_article_id  (associated_article_id)
#  index_articles_on_author_id              (author_id)
#  index_articles_on_portal_id              (portal_id)
#  index_articles_on_slug                   (slug) UNIQUE
#  index_articles_on_status                 (status)
#  index_articles_on_views                  (views)
#
class Article < ApplicationRecord
  include PgSearch::Model
  include LlmFormattable

  has_many :associated_articles,
           class_name: :Article,
           foreign_key: :associated_article_id,
           dependent: :nullify,
           inverse_of: 'root_article'

  belongs_to :root_article,
             class_name: :Article,
             foreign_key: :associated_article_id,
             inverse_of: :associated_articles,
             optional: true
  belongs_to :account
  belongs_to :category, optional: true
  belongs_to :portal
  belongs_to :author, class_name: 'User', inverse_of: :articles

  before_validation :ensure_account_id
  before_validation :ensure_article_slug
  before_validation :ensure_locale_in_article
  before_validation :associate_with_root_article, if: :will_save_change_to_associated_article_id?

  # Slugs that collide with help center routes (e.g. /hc/:slug/:locale/search)
  RESERVED_SLUGS = %w[search articles categories].freeze

  validates :account_id, presence: true
  validates :author_id, presence: true
  validates :title, presence: true
  validates :content, presence: true, if: :published?
  validates :slug, exclusion: { in: RESERVED_SLUGS }
  validate :cannot_reassociate_translation_family, if: -> { persisted? && will_save_change_to_associated_article_id? }
  validate :unique_published_locale_in_translation_family, if: :published?

  # ensuring that the position is always set correctly
  before_create :add_position_to_article
  after_save :category_id_changed_action, if: :saved_change_to_category_id?

  enum status: { draft: 0, published: 1, archived: 2 }

  scope :search_by_category_slug, ->(category_slug) { where(categories: { slug: category_slug }) if category_slug.present? }
  scope :search_by_category_locale, ->(locale) { where(categories: { locale: locale }) if locale.present? }
  scope :search_by_locale, ->(locale) { where(locale: locale) if locale.present? }
  scope :search_by_author, ->(author_id) { where(author_id: author_id) if author_id.present? }
  scope :search_by_status, ->(status) { where(status: status) if status.present? }
  scope :order_by_updated_at, -> { reorder(updated_at: :desc) }
  scope :order_by_position, -> { reorder(position: :asc) }
  scope :order_by_views, -> { reorder(views: :desc) }

  # TODO: if text search slows down https://www.postgresql.org/docs/current/textsearch-features.html#TEXTSEARCH-UPDATE-TRIGGERS
  # - the A, B and C are for weightage. See: https://github.com/Casecommons/pg_search#weighting
  # - the normalization is for ensuring the long articles that mention the search term too many times are not ranked higher.
  #   it divides rank by log(document_length) to prevent longer articles from ranking higher just due to sizeSee: https://github.com/Casecommons/pg_search#normalization
  # - the ranking is to ensure that articles with higher weightage are ranked higher
  pg_search_scope(
    :text_search,
    against: {
      title: 'A',
      description: 'B',
      content: 'C'
    },
    using: {
      tsearch: {
        prefix: true,
        normalization: 2
      }
    },
    ranked_by: ':tsearch'
  )

  def self.search(params)
    records = left_outer_joins(
      :category
    ).search_by_category_slug(
      params[:category_slug]
    ).search_by_locale(params[:locale]).search_by_author(params[:author_id]).search_by_status(params[:status])

    records = records.text_search(params[:query]) if params[:query].present?
    records
  end

  def self.find_root_article_id(article)
    current_article = article
    visited_ids = []

    while current_article.associated_article_id.present? && visited_ids.exclude?(current_article.id)
      visited_ids << current_article.id
      root_article = current_article.root_article
      break if root_article.nil?

      current_article = root_article
    end

    current_article.id
  end

  def draft!
    update(status: :draft)
  end

  def increment_view_count
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:views, views? ? views + 1 : 1)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def self.update_positions(portal:, positions_hash:)
    return {} if positions_hash.blank?

    moved_ids = positions_hash.keys.map(&:to_i)

    transaction do
      positions_hash.each do |article_id, new_position|
        portal.articles.find(article_id).update!(position: new_position)
      end
      # Re-space touched categories to clean gaps and return the final positions
      rebalance_positions(portal, moved_ids)
    end
  end

  def self.rebalance_positions(portal, moved_ids)
    category_ids = portal.articles.where(id: moved_ids).distinct.pluck(:category_id).compact
    category_ids.each_with_object({}) do |category_id, positions|
      resequence_category(portal, category_id, moved_ids, positions)
    end
  end

  def self.resequence_category(portal, category_id, moved_ids, positions)
    ordered = portal.articles.where(category_id: category_id)
                    .sort_by { |article| [article.position || 0, moved_ids.include?(article.id) ? 1 : 0, article.id] }
    return if ordered.length < 2 # a lone article can't collide, leave it as-is

    ordered.each_with_index do |article, index|
      new_position = (index + 1) * 10
      positions[article.id] = new_position
      next if article.position == new_position

      article.update_column(:position, new_position) # rubocop:disable Rails/SkipsModelValidations
    end
  end
  private_class_method :rebalance_positions, :resequence_category

  private

  def associate_with_root_article
    article = portal&.articles&.find_by(id: associated_article_id)
    self.associated_article_id = self.class.find_root_article_id(article) if article
  end

  def unique_published_locale_in_translation_family
    root_id = self.class.find_root_article_id(self)
    return if root_id.blank? || locale.blank?

    lock_translation_family_roots(root_id)
    matching_articles = portal.articles.published.where(id: translation_family_ids(root_id), locale: locale)
    matching_articles = matching_articles.where.not(id: id) if persisted?
    errors.add(:locale, :taken) if matching_articles.exists?
  end

  def cannot_reassociate_translation_family
    errors.add(:associated_article_id, :invalid) if associated_articles.exists?
  end

  def lock_translation_family_roots(root_id)
    root_ids = [root_id]

    if persisted? && will_save_change_to_associated_article_id?
      previous_parent_id = associated_article_id_in_database
      previous_root_id = previous_parent_id ? self.class.find_root_article_id(portal.articles.find(previous_parent_id)) : id
      root_ids << previous_root_id
    end

    portal.articles.where(id: root_ids.compact.uniq.sort).order(:id).lock.load
  end

  def translation_family_ids(root_id)
    article_ids = [root_id]
    parent_ids = [root_id]

    while parent_ids.any?
      parent_ids = portal.articles.where(associated_article_id: parent_ids).where.not(id: article_ids).pluck(:id)
      article_ids.concat(parent_ids)
    end

    article_ids
  end

  def category_id_changed_action
    # We need to update the position of the article in the new category
    return unless persisted?

    # this means the article is just created
    # and the category_id is newly set
    # and the position is already present
    return if created_at_before_last_save.nil? && position.present? && category_id_before_last_save.nil?

    update_article_position_in_category
  end

  def ensure_locale_in_article
    self.locale = if category.present?
                    category.locale
                  else
                    locale.presence || portal.default_locale
                  end
  end

  def add_position_to_article
    # on creation if a position is already present, ignore it
    return if position.present?

    update_article_position_in_category
  end

  def update_article_position_in_category
    max_position = Article.where(category_id: category_id, account_id: account_id).maximum(:position)

    new_position = max_position.present? ? max_position + 10 : 10

    # update column to avoid validations if the article is already persisted
    if persisted?
      # rubocop:disable Rails/SkipsModelValidations
      update_column(:position, new_position)
      # rubocop:enable Rails/SkipsModelValidations
    else
      self.position = new_position
    end
  end

  def ensure_account_id
    self.account_id = portal&.account_id
  end

  def ensure_article_slug
    self.slug ||= "#{Time.now.utc.to_i}-#{title.underscore.parameterize(separator: '-')}" if title.present?
  end
end
Article.include_mod_with('Concerns::Article')
