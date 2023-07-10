class CrawlerService
  attr_reader :response_source

  def initialize(response_source)
    @response_source = response_source
  end

  def perform
    session = Capybara::Session.new(:selenium)
    session.visit(response_source.source_link)

    links = Set.new

    # Get all link elements
    a_tags = session.all('a')

    # Extract the href attribute from each link
    a_tags.map do |tag|
      links.add(tag[:href])
    end

    create_response_documents(links)
  end

  private

  def create_response_documents(links)
    links.each do |link|
      next if link.blank?

      response_document = response_source.response_documents.find_or_initialize_by(
        document_link: link,
        account_id: response_source.account_id
      )
      next if response_document.persisted?

      response_document.response_source = response_source
      response_document.save!
      ResponseDocumentContentJob.perform_later(response_document)
    end
  end
end
