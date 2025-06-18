class NotionToMarkdown
  # Main entry: pass in the Notion page blocks (array of block hashes)
  def convert(blocks)
    blocks.map { |block| block_to_markdown(block) }.join("\n\n")
  end

  private

  def block_to_markdown(block, depth = 0)
    type = block['type']
    return '' unless type

    case type
    when 'paragraph'
      rich_text_to_md(block['paragraph']['rich_text'])
    when 'heading_1'
      "# #{rich_text_to_md(block['heading_1']['rich_text'])}"
    when 'heading_2'
      "## #{rich_text_to_md(block['heading_2']['rich_text'])}"
    when 'heading_3'
      "### #{rich_text_to_md(block['heading_3']['rich_text'])}"
    when 'bulleted_list_item'
      indent = '  ' * depth
      "#{indent}- #{rich_text_to_md(block['bulleted_list_item']['rich_text'])}" +
        children_to_md(block, depth + 1)
    when 'numbered_list_item'
      indent = '  ' * depth
      "#{indent}1. #{rich_text_to_md(block['numbered_list_item']['rich_text'])}" +
        children_to_md(block, depth + 1)
    when 'to_do'
      box = block['to_do']['checked'] ? '[x]' : '[ ]'
      "- #{box} #{rich_text_to_md(block['to_do']['rich_text'])}"
    when 'toggle'
      summary = rich_text_to_md(block['toggle']['rich_text'])
      details = children_to_md(block, depth + 1)
      "<details>\n<summary>#{summary}</summary>\n\n#{details}\n</details>"
    when 'quote'
      quote = rich_text_to_md(block['quote']['rich_text'])
      quote_lines = quote.lines.map { |line| "> #{line}" }.join
      quote_lines + children_to_md(block, depth)
    when 'code'
      lang = block['code']['language'] || ''
      code = block['code']['rich_text'].map { |t| t['plain_text'] }.join
      "```#{lang}\n#{code}\n```"
    when 'callout'
      icon = block['callout']['icon']&.dig('emoji') || '💡'
      content = rich_text_to_md(block['callout']['rich_text'])
      "> [!#{icon}] #{content}" + children_to_md(block, depth + 1)
    when 'divider'
      '---'
    when 'image'
      url = block['image']['type'] == 'external' ? block['image']['external']['url'] : block['image']['file']['url']
      caption = block['image']['caption']&.map { |c| c['plain_text'] }&.join || 'image'
      "![#{caption}](#{url})"
    when 'bookmark'
      url = block['bookmark']['url']
      "[#{url}](#{url})"
    when 'child_page'
      "## #{block['child_page']['title']}" + children_to_md(block, depth + 1)
    when 'table'
      table_to_md(block)
    else
      '' # Add more block types as needed
    end
  end

  def children_to_md(block, depth)
    return '' unless block['has_children'] && block['children']

    "\n" + block['children'].map { |child| block_to_markdown(child, depth) }.join("\n")
  end

  def rich_text_to_md(rich_text_array)
    return '' unless rich_text_array

    rich_text_array.map { |t| annotate_text(t) }.join
  end

  def annotate_text(text_obj)
    text = text_obj['plain_text']
    ann = text_obj['annotations'] || {}

    text = "**#{text}**" if ann['bold']
    text = "*#{text}*" if ann['italic']
    text = "~~#{text}~~" if ann['strikethrough']
    text = "<u>#{text}</u>" if ann['underline']
    text = "`#{text}`" if ann['code']
    text = "[#{text}](#{text_obj['href']})" if text_obj['href']
    text
  end

  def table_to_md(block)
    rows = block['children'] || []
    table = rows.map do |row|
      cells = row['table_row']['cells']
      cells.map { |cell| rich_text_to_md(cell) }
    end
    return '' if table.empty?

    header = table.first
    sep = header.map { '---' }
    ([header, sep] + table[1..]).map { |row| "| #{row.join(' | ')} |" }.join("\n")
  end
end