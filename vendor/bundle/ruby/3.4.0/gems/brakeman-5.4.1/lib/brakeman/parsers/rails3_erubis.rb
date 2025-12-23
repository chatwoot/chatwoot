Brakeman.load_brakeman_dependency 'erubis'

# This is from Rails 5 version of the Erubis handler
# https://github.com/rails/rails/blob/ec608107801b1e505db03ba76bae4a326a5804ca/actionview/lib/action_view/template/handlers/erb.rb#L7-L73
class Brakeman::Rails3Erubis < ::Erubis::Eruby

  def add_preamble(src)
    @newline_pending = 0
    src << "@output_buffer = output_buffer || ActionView::OutputBuffer.new;"
  end

  def add_text(src, text)
    return if text.empty?

    if text == "\n"
      @newline_pending += 1
    else
      src << "@output_buffer.safe_append='"
      src << "\n" * @newline_pending if @newline_pending > 0
      src << escape_text(text)
      src << "'.freeze;"

      @newline_pending = 0
    end
  end

  # Erubis toggles <%= and <%== behavior when escaping is enabled.
  # We override to always treat <%== as escaped.
  def add_expr(src, code, indicator)
    case indicator
    when '=='
      add_expr_escaped(src, code)
    else
      super
    end
  end

  BLOCK_EXPR = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/

  def add_expr_literal(src, code)
    flush_newline_if_pending(src)
    if code =~ BLOCK_EXPR
      src << '@output_buffer.append= ' << code
    else
      src << '@output_buffer.append=(' << code << ');'
    end
  end

  def add_expr_escaped(src, code)
    flush_newline_if_pending(src)
    if code =~ BLOCK_EXPR
      src << "@output_buffer.safe_expr_append= " << code
    else
      src << "@output_buffer.safe_expr_append=(" << code << ");"
    end
  end

  def add_stmt(src, code)
    flush_newline_if_pending(src)
    super
  end

  def add_postamble(src)
    flush_newline_if_pending(src)
    src << '@output_buffer.to_s'
  end

  def flush_newline_if_pending(src)
    if @newline_pending > 0
      src << "@output_buffer.safe_append='#{"\n" * @newline_pending}'.freeze;"
      @newline_pending = 0
    end
  end

  # This is borrowed from graphql's erb plugin:
  # https://github.com/github/graphql-client/blob/51e76bd8d8b2ac0021d8fef7468b9a294e4bd6e8/lib/graphql/client/erubis.rb#L33-L38
  def convert_input(src, input)
    input = input.gsub(/<%graphql/, "<%#")
    super(src, input)
  end
end
