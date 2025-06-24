class Integrations::Notion::ProcessorService
  pattr_initialize [:account!]

  def search_pages(query, sort = nil)
    response = notion_client.search(query, sort)
    return { error: response[:error] } if response[:error]

    response['results'].map { |page| format_page(page) }
  end

  def page(page_id)
    response = notion_client.page(page_id)
    return { error: response[:error] } if response[:error]

    format_page(response)
  end

  def full_page(page_id)
    # Get page metadata
    page_response = notion_client.page(page_id)
    return { error: page_response[:error] } if page_response[:error]

    # Get page content blocks
    blocks_response = notion_client.page_blocks(page_id)
    return { error: blocks_response[:error] } if blocks_response[:error]

    # Use presenter to format the complete page data
    NotionPagePresenter.new(page_response, blocks_response).to_hash
  end

  private

  def format_page(page_response)
    {
      'id' => page_response['id'],
      'icon' => page_response['icon'],
      'title' => extract_page_title(page_response),
      'created_time' => page_response['created_time'],
      'last_edited_time' => page_response['last_edited_time']
    }
  end

  def page_title(page_id)
    page_response = notion_client.page(page_id)
    return nil if page_response[:error]

    extract_page_title(page_response)
  end

  def extract_page_title(page_response)
    # Try to get title from properties (for database pages)
    if page_response['properties']
      title_property = page_response['properties'].values.find { |prop| prop['type'] == 'title' }
      return title_property['title'].map { |t| t['plain_text'] }.join if title_property && title_property['title']&.any?
    end

    nil
  end

  def notion_hook
    @notion_hook ||= account.hooks.find_by!(app_id: 'notion')
  end

  def notion_client
    @notion_client ||= Notion.new(notion_hook.access_token)
  end
end
