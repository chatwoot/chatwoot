module WebCrawling::Types
  # These types preserve immutable boundaries while normalizing results from the native, Firecrawl, and Context.dev spiders.
  Page = Data.define(:url, :title, :markdown, :status_code, :error_code) do
    def initialize(url:, title: nil, markdown: nil, status_code: nil, error_code: nil)
      super
    end
  end

  DiscoveredPage = Data.define(:url, :title, :description) do
    def initialize(url:, title: nil, description: nil)
      super
    end
  end

  CrawlSubmission = Data.define(:provider, :external_id, :status, :metadata) do
    def initialize(provider:, status:, external_id: nil, metadata: {})
      super
    end
  end

  BatchResults = Data.define(:pages, :has_more, :next_cursor) do
    def initialize(pages:, has_more:, next_cursor: nil)
      super(pages: pages.freeze, has_more: has_more, next_cursor: next_cursor)
    end
  end
end
