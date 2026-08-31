# cmark parses a dashes/equals line sitting directly under a hard-break
# backslash ("\" + newline) as a setext heading underline: the dashes vanish
# into markup and the stray "\" renders as heading text. The reply editor
# serializes an empty line above the "--" signature delimiter exactly that
# way. Escaping the underline keeps it literal text (matching the dashboard,
# which disables setext parsing), while intentional setext headings — no
# trailing backslash — stay untouched. Stored content can be CRLF, so both
# line endings are handled.
module MarkdownSetextEscape
  UNDERLINE_AFTER_HARD_BREAK = /\\\r?\n(?=(?:-+|=+)[ \t]*\r?(?:\n|\z))/

  def self.call(content)
    content.gsub(UNDERLINE_AFTER_HARD_BREAK) { |hard_break| "#{hard_break}\\" }
  end
end
