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
    @list_type = node.list_type
    @list_item_number = @list_type == :ordered_list ? node.list_start : 0
    out(:children)
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
