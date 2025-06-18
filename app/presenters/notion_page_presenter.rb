class NotionPagePresenter
  def initialize(page_response, blocks_response)
    @page_response = page_response
    @blocks_response = blocks_response
  end

  def to_hash
    {
      'id' => @page_response['id'],
      'icon' => @page_response['icon'],
      'title' => extract_page_title,
      'created_time' => @page_response['created_time'],
      'last_edited_time' => @page_response['last_edited_time'],
      'md' => generate_markdown,
      'child_pages' => extract_child_pages
    }
  end

  private

  def extract_page_title
    # Try to get title from properties (for database pages)
    if @page_response['properties']
      title_property = @page_response['properties'].values.find { |prop| prop['type'] == 'title' }
      return title_property['title'].map { |t| t['plain_text'] }.join if title_property && title_property['title']&.any?
    end

    nil
  end

  def generate_markdown
    title = extract_page_title
    content_md = NotionToMarkdown.new.convert(@blocks_response['results'])
    title_md = title ? "# #{title}\n\n" : ''

    "#{title_md}#{content_md}"
  end

  def extract_child_pages
    extract_child_pages_from_blocks(@blocks_response['results'])
  end

  def extract_child_pages_from_blocks(blocks)
    child_pages = []

    blocks.each do |block|
      if block['type'] == 'child_page'
        child_pages << {
          'id' => block['id'],
          'title' => block['child_page']['title']
        }
      end

      # Recursively check nested blocks
      child_pages.concat(extract_child_pages_from_blocks(block['children'])) if block['has_children'] && block['children']
    end

    child_pages
  end
end