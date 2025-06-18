class Integrations::Notion::ProcessorService
  pattr_initialize [:account!]

  def search_pages(query, sort = nil)
    response = notion_client.search(query, sort)
    return { error: response[:error] } if response[:error]

    response['results'].map(&:as_json)
  end

  def page(page_id)
    response = notion_client.page(page_id)
    return { error: response[:error] } if response[:error]

    response.as_json
  end

  def page_md(page_id)
    # Get page content blocks
    blocks_response = notion_client.page_blocks(page_id)
    return { error: blocks_response[:error] } if blocks_response[:error]

    # Convert blocks to markdown
    NotionToMarkdown.new.convert(blocks_response['results'])
  end

  private

  def notion_hook
    @notion_hook ||= account.hooks.find_by!(app_id: 'notion')
  end

  def notion_client
    @notion_client ||= Notion.new(notion_hook.access_token)
  end
end