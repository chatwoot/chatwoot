Brakeman.load_brakeman_dependency 'erubis'

#This is from the rails_xss plugin for Rails 2
class Brakeman::Rails2XSSPluginErubis < ::Erubis::Eruby
  def add_preamble(src)
    #src << "@output_buffer = ActiveSupport::SafeBuffer.new;"
  end

  #This is different from rails_xss - fixes some line number issues
  def add_text(src, text)
    if text == "\n"
      src << "\n"
    elsif text.include? "\n"
      lines = text.split("\n")
      if text.match(/\n\z/)
        lines.each do |line|
          src << "@output_buffer.safe_concat('" << escape_text(line) << "');\n"
        end
      else
        lines[0..-2].each do |line|
          src << "@output_buffer.safe_concat('" << escape_text(line) << "');\n"
        end

        src << "@output_buffer.safe_concat('" << escape_text(lines.last) << "');"
      end
    else
      src << "@output_buffer.safe_concat('" << escape_text(text) << "');"
    end
  end

  BLOCK_EXPR = /\s+(do|\{)(\s*\|[^|]*\|)?\s*\Z/

  def add_expr_literal(src, code)
    if code =~ BLOCK_EXPR
      src << "@output_buffer.safe_concat((" << $1 << ").to_s);"
    else
      src << '@output_buffer << ((' << code << ').to_s);'
    end
  end

  def add_expr_escaped(src, code)
    src << '@output_buffer << ' << escaped_expr(code) << ';'
  end

  def add_postamble(src)
    #src << '@output_buffer.to_s'
  end
end
