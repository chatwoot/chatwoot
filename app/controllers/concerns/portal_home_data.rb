module PortalHomeData
  extend ActiveSupport::Concern

  private

  def load_home_data
    base_articles = @portal.articles.published.where(locale: @locale).includes(:author, :category)
    @visible_categories = @portal.categories
                                 .where(locale: @locale)
                                 .joins(:articles).where(articles: { status: :published })
                                 .order(position: :asc)
                                 .group('categories.id')
    @popular_topics = @visible_categories.first(3)
    @featured = base_articles.order_by_views.limit(6)
    @category_contributors = build_category_contributors(@visible_categories)
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
