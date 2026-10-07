module PortalHomeData
  extend ActiveSupport::Concern

  private

  def load_home_data
    load_recommended_content
    # The classic hero only needs the recommendations above; the rest is
    # documentation-layout home data (also used on custom-domain home pages).
    return unless @portal.layout == 'documentation'

    @visible_categories = @portal.categories
                                 .where(locale: @locale)
                                 .joins(:articles).where(articles: { status: :published })
                                 .order(position: :asc)
                                 .group('categories.id')
    @popular_topics = @recommended_categories.presence || @visible_categories.first(3)
    @featured = base_articles.order_by_views.limit(6)
    @category_contributors = build_category_contributors(@visible_categories)
  end

  def load_recommended_content
    @recommended_categories = recommended_categories
    @recommended_articles = recommended_articles
  end

  def base_articles
    @base_articles ||= @portal.articles.published.where(locale: @locale).includes(:author, :category)
  end

  # Admin-recommended categories for the locale, in the chosen order. Unlike the
  # position-based fallback, published articles aren't required: the admin's pick wins.
  def recommended_categories
    ids = @portal.popular_category_ids(@locale)
    ordered_by_ids(@portal.categories.where(locale: @locale, id: ids), ids)
  end

  # Admin-recommended articles for the locale, in the chosen order, limited to
  # published articles that still exist.
  def recommended_articles
    ids = @portal.popular_article_ids(@locale)
    ordered_by_ids(base_articles.where(id: ids), ids)
  end

  # Loads the scope and returns its records ordered to match `ids`, dropping any
  # that no longer exist. Skips the query entirely when `ids` is blank.
  def ordered_by_ids(scope, ids)
    return [] if ids.blank?

    by_id = scope.index_by(&:id)
    ids.filter_map { |id| by_id[id] }
  end

  def build_category_contributors(categories)
    category_ids = categories.map(&:id)
    return {} if category_ids.empty?

    @portal.articles
           .published
           .where(locale: @locale, category_id: category_ids)
           .includes(:author)
           .group_by(&:category_id)
           .transform_values { |articles| articles.filter_map(&:author).uniq.first(3) }
  end
end
