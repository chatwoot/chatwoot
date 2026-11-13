class Captain::Copilot::Resources::Articles < Captain::Copilot::Resources::BaseResource
  NAME = 'articles'.freeze
  MODEL = Article
  DATE_FIELDS = %w[updated_at created_at].freeze
  FILTERS = { search: { type: 'string', minLength: 2, description: 'Matches title or content' } }.freeze
  SOURCES = {}.freeze
  COLUMNS = %w[Portal Status Updated].freeze
  PRELOAD = [:portal].freeze

  # The same permission as the help center pages and the article tools.
  def readable?
    permitted?('knowledge_base_manage')
  end

  def scope
    raise ArgumentError, 'You do not have permission to view help center articles' unless readable?

    @account.articles
  end

  def filter(relation, filters)
    return relation if filters['search'].blank?

    term = "%#{Article.sanitize_sql_like(filters['search'])}%"
    relation.where(Article.arel_table[:title].matches(term).or(Article.arel_table[:content].matches(term)))
  end

  # The dashboard's article editor takes the article ID in its articleSlug route parameter.
  def row(article)
    { label: article.title, url: url("portals/#{article.portal.slug}/#{article.locale}/articles/edit/#{article.id}"),
      values: [article.portal.name, article.status, article.updated_at.to_date] }
  end
end
