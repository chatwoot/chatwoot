class Messages::MarkdownRenderers::TelegramRenderer < Messages::MarkdownRenderers::BaseMarkdownRenderer
  def initialize
    super
    @list_item_number = 0
  end

  def strong(_node)
    out('<strong>', :children, '</strong>')
  end

  def emph(_node)
    out('<em>', :children, '</em>')
  end

  def code(node)
    out('<code>', node.string_content, '</code>')
  end

  def link(node)
    out('<a href="', node.url, '">', :children, '</a>')
  end

  def strikethrough(_node)
    out('<del>', :children, '</del>')
  end

  def blockquote(_node)
    out('<blockquote>', :children, '</blockquote>')
  end

  def code_block(node)
    out('<pre>', node.string_content, '</pre>')
  end

  def list(node)
    # Lists nest, so remember the enclosing list's state and restore it once the
    # children are rendered. Otherwise an inner list overwrites its parent's type
    # and counter, and the parent's remaining items render with the wrong marker.
    parent_type = @list_type
    parent_item_number = @list_item_number
    @list_type = node.list_type
    @list_item_number = @list_type == :ordered_list ? node.list_start : 0
    out(:children)
    @list_type = parent_type
    @list_item_number = parent_item_number
    cr
  end

  def list_item(_node)
    if @list_type == :ordered_list
      out("#{@list_item_number}. ", :children)
      @list_item_number += 1
    else
      out('• ', :children)
    end
    cr
  end

  def header(_node)
    out('<strong>', :children, '</strong>')
    cr
  end

  def softbreak(_node)
    out("\n")
  end
end
