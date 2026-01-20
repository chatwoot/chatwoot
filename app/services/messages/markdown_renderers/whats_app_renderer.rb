class Messages::MarkdownRenderers::WhatsAppRenderer < Messages::MarkdownRenderers::BaseMarkdownRenderer
  def strong(_node)
    out('*', :children, '*')
  end

  def emph(_node)
    out('_', :children, '_')
  end

  def code(node)
    out('`', node.string_content, '`')
  end

  def link(node)
    out(node.url)
  end

  def list(_node)
    out(:children)
    cr
  end

  def list_item(_node)
    out('- ', :children)
    cr
  end

  def blockquote(_node)
    out('> ', :children)
    cr
  end

  def code_block(node)
    out(node.string_content)
  end

  def softbreak(_node)
    out("\n")
  end
end
