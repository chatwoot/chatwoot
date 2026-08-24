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

  def crawl(url:, limit:, callback_url: nil)
    raise NotImplementedError
  end
end
