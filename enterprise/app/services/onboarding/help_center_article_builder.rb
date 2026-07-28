class Onboarding::HelpCenterArticleBuilder
  BuildFailed = Onboarding::HelpCenterErrors::ArticleBuildFailed

  def initialize(account:, portal:, user:, article:)
    @account = account
    @portal = portal
    @user = user

    spec = article.with_indifferent_access
    @urls = Array(spec[:urls]).map(&:to_s).reject(&:blank?)
    @title = spec[:title]
    @category_id = spec[:category_id]
  end

  def perform
    raise BuildFailed, 'no source urls supplied' if @urls.empty?

    source_pages = scrape(@urls)
    raise BuildFailed, "scrape produced no usable pages for #{@urls.join(', ')}" if source_pages.empty?

    payload = rewrite(source_pages)

    @portal.articles.create!(
      title: payload[:title],
      description: payload[:description].presence,
      content: payload[:content],
      author_id: @user.id,
      category_id: @category_id,
      status: :draft,
      meta: { source_urls: source_pages.pluck(:url) }
    )
  end

  private

  def scrape(urls)
    job = Firecrawl::Configuration.client.batch_scrape(
      urls,
      Firecrawl::Models::BatchScrapeOptions.new(options: Firecrawl::Configuration.default_scrape_options)
    )
    Array(job.data).filter_map { |doc| normalize(doc) }
  end

  def normalize(doc)
    metadata = doc&.metadata || {}
    status = metadata['statusCode']
    return nil if status.present? && !(200..299).cover?(status)
    return nil if doc.markdown.to_s.blank?

    {
      url: metadata['sourceURL'] || metadata['url'],
      markdown: doc.markdown.to_s,
      page_title: metadata['title'].to_s.strip
    }
  end

  def rewrite(source_pages)
    response = Captain::Llm::ArticleWriterService.new(
      account: @account,
      source_pages: source_pages,
      hint_title: @title.presence || source_pages.first[:page_title]
    ).perform
    raise BuildFailed, "writer LLM error: #{response[:error]}" if response[:error]

    payload = response[:message] || {}
    raise BuildFailed, 'writer returned blank content' if payload[:content].blank?
    raise BuildFailed, 'writer returned blank title' if payload[:title].blank?

    payload
  end
end
