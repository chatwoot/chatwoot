# Strips CommonMark hard line breaks from stored markdown source (backslash before newline).
# ProseMirror / the dashboard editor emits this form so soft breaks survive as markdown;
# webhook consumers expect plain newlines without a visible backslash (e.g. WhatsApp gateways).
# The editor also escapes a `-`/`--`/`==` line under a hard break as `\--` so cmark cannot
# read the pair as a setext heading. That escape is only ever written as one `\<newline>\`
# unit (glue backslash, newline, escape backslash), so it is unescaped only in that exact
# context and never inside a code block, where the same byte sequence is user content.
# Also strips trailing newlines introduced by TipTap/ProseMirror trailing paragraphs.
class Messages::WebhookContentNormalizer
  DELIMITER_ESCAPE = /(\\\r?\n)\\(?=(?:-+|=+)[ \t]*\r?$)/

  def self.normalize(text)
    return text if text.blank?

    unescape_delimiters(text)
      .gsub(/\\\r?\n/, "\n")
      .sub(/(\r?\n)+\z/, '')
  end

  def self.unescape_delimiters(text)
    return text unless text.match?(DELIMITER_ESCAPE)

    code_lines = code_block_lines(text)
    text.gsub(DELIMITER_ESCAPE) do
      match = Regexp.last_match
      code_lines.include?(match.pre_match.count("\n") + 2) ? match[0] : match[1]
    end
  end

  def self.code_block_lines(text)
    lines = Set.new
    CommonMarker.render_doc(text).walk do |node|
      next unless node.type == :code_block

      lines.merge(node.sourcepos[:start_line]..node.sourcepos[:end_line])
    end
    lines
  end

  private_class_method :unescape_delimiters, :code_block_lines
end
