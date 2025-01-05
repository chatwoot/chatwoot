class Captain::Documents::CrawlerService
  def initialize(url)
    @url = url
  end

  def perform
    response = HTTP.get(@url)
    Nokogiri::HTML(response.body.to_s).text
  end
end
