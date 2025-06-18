class Captain::Tools::NotionCrawlService
  # The crawler will go 4 levels from the root. 5 levels in total
  MAX_CRAWL_DEPTH = 4

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

  def extract_child_pages(page_id, visited = Set.new, current_depth = 0)
    return [] if visited.include?(page_id)
    return [] if current_depth >= MAX_CRAWL_DEPTH

    visited.add(page_id)

    child_pages = []
    page_data = processor_service.full_page(page_id)

    return child_pages if page_data[:error]

    page_data['child_pages']&.each do |child_page|
      child_id = child_page['id']
      child_pages << child_id
      child_pages.concat(extract_child_pages(child_id, visited, current_depth + 1))
    end

    child_pages
  end

  def processor_service
    @processor_service ||= Integrations::Notion::ProcessorService.new(account: account)
  end
end
