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

  def strikethrough(_node)
    out('<del>')
    out(:children)
    out('</del>')
  end

  def method_missing(method_name, node = nil, *args, **kwargs, &)
    return super unless node.is_a?(CommonMarker::Node)

    out(:children)
    cr unless %i[text softbreak linebreak].include?(node.type)
  end

  def respond_to_missing?(_method_name, _include_private = false)
    true
  end
end
