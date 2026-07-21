class Messages::MarkdownRenderers::InstagramRenderer < Messages::MarkdownRenderers::BaseMarkdownRenderer
  def initialize
    super
    @list_item_number = 0
  end

  def strong(_node)
    out('*', :children, '*')
  end

  def emph(_node)
    out('_', :children, '_')
  end

  def code(node)
    out(node.string_content)
  end

  def link(node)
    out(node.url)
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
      out('- ', :children)
    end
    cr
  end

  def blockquote(_node)
    out(:children)
    cr
  end

  def code_block(node)
    out(node.string_content)
  end

  def softbreak(_node)
    out("\n")
  end
end
