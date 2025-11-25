class Messages::MarkdownRenderers::BaseMarkdownRenderer < CommonMarker::Renderer
  def document(_node)
    out(:children)
  end

  def paragraph(_node)
    out(:children)
    cr
  end

  def text(node)
    out(node.string_content)
  end

  def softbreak(_node)
    out(' ')
  end

  def linebreak(_node)
    out("\n")
  end
end
