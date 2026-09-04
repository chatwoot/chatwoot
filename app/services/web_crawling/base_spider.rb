class WebCrawling::BaseSpider
  class << self
    def configured?
      true
    end
  end

  def discover(url:, limit:, query: nil)
    raise NotImplementedError
  end

  def scrape(url:)
    raise NotImplementedError
  end

  def scrape_many(urls:)
    urls.map { |url| scrape(url: url) }
  end

  # request_id is used as the idempotency key by providers that support idempotent crawl submission.
  def crawl(url:, limit:, callback_url: nil, request_id: nil)
    raise NotImplementedError
  end
end
