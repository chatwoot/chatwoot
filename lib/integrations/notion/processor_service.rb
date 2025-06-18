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

  def page_md(page_id)
    # Get page metadata
    page_data = page(page_id)
    return page_data if page_data[:error]

    # Get page content blocks
    blocks_response = notion_client.page_blocks(page_id)
    return { error: blocks_response[:error] } if blocks_response[:error]

    # Convert blocks to markdown
    content_md = NotionToMarkdown.new.convert(blocks_response['results'])
    title_md = page_data['title'] ? "# #{page_data['title']}\n\n" : ''

    # Add markdown to page data
    page_data.merge('md' => "#{title_md}#{content_md}")
  end

  private

  def format_page(page_response)
    {
      'id' => page_response['id'],
      'icon' => page_response['icon'],
      'title' => extract_page_title(page_response),
      'created_time' => page_response['created_time'],
      'last_edited_time' => page_response['last_edited_time'],
      '_raw' => page_response
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
