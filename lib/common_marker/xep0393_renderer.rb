# frozen_string_literal: true

class CommonMarker::Xep0393Renderer < CommonMarker::Renderer
  def out(*args)
    @quote_depth ||= 0

    args.each do |arg|
      next super(arg) if arg.is_a?(Array) || arg.is_a?(CommonMarker::Node) || arg == :children

      super arg.to_s.gsub(/^(?!$)/, ('>' * @quote_depth) + (@quote_depth.positive? ? ' ' : ''))
    end
  end

  def header(node)
    block do
      out('#' * node.header_level, ' ', :children)
    end
  end

  def paragraph(node)
    if @list_type && node.parent.type != :blockquote
      out(:children)
    else
      block do
        out(:children)
      end
    end
  end

  def list(node)
    old_list_idx = @list_idx
    old_list_type = @list_type
    @list_idx = 1
    @list_type = node.list_type
    block do
      out(:children)
    end
    @list_idx = old_list_idx
    @list_type = old_list_type
  end

  def list_item(_)
    block do
      if @list_type == :bullet_list
        out('* ')
      else
        out("#{@list_idx}. ")
      end
      out(:children)
    end
    @list_idx += 1
  end

  def blockquote(_)
    @quote_depth ||= 0
    @quote_depth += 1
    block do
      out(:children)
    end
    @quote_depth -= 1
  end

  def hrule(_)
    block do
      out('---')
    end
  end

  def code_block(node)
    block do
      out('```')
      out(node.fence_info.split(/\s+/)[0]) if node.fence_info.present?
      cr
      out(node.string_content)
      out('```')
    end
  end

  def html(_); end

  def inline_html(_); end

  def emph(_)
    out('_', :children, '_')
  end

  def strong(_)
    out('*', :children, '*')
  end

  def link(node)
    out(:children, ' (', node.url, ')')
  end

  def image(node)
    out(node.url, node.first_child ? [' (', :children, ')'] : '')
  end

  def text(node)
    out(node.string_content)
  end

  def code(node)
    out('`')
    out(node.string_content)
    out('`')
  end

  def linebreak(_node)
    out('\n')
  end

  def softbreak(_)
    if option_enabled?(:HARDBREAKS)
      out('\n')
    elsif option_enabled?(:NOBREAKS)
      out(' ')
    else
      cr
    end
  end

  def table(node)
    out(node.to_plaintext)
  end

  def table_header(node)
    out(node.to_plaintext)
  end

  def table_row(node)
    out(node.to_plaintext)
  end

  def table_cell(node)
    out(node.to_plaintext)
  end

  def strikethrough(_)
    out('~', :children, '~')
  end
end
