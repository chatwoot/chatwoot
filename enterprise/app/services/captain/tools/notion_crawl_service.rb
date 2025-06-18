class Captain::Tools::NotionCrawlService
  attr_reader :account, :page_id

  def initialize(account, page_id)
    @account = account
    @page_id = page_id
  end

  def page_ids
    @page_ids ||= begin
      result = [page_id]
      child_pages = extract_child_pages(page_id)
      result.concat(child_pages)
      result.uniq
    end
  end

  private

  def extract_child_pages(page_id, visited = Set.new)
    return [] if visited.include?(page_id)

    visited.add(page_id)

    child_pages = []
    page_data = processor_service.full_page(page_id)

    return child_pages if page_data[:error]

    page_data['child_pages']&.each do |child_page|
      child_id = child_page['id']
      child_pages << child_id
      child_pages.concat(extract_child_pages(child_id, visited))
    end

    child_pages
  end

  def processor_service
    @processor_service ||= Integrations::Notion::ProcessorService.new(account: account)
  end
end