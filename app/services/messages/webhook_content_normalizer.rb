# Strips CommonMark hard line breaks from stored markdown source (backslash before newline).
# ProseMirror / the dashboard editor emits this form so soft breaks survive as markdown;
# webhook consumers expect plain newlines without a visible backslash (e.g. WhatsApp gateways).
# The editor also escapes a `-`/`--`/`==` line under a hard break as `\--` so cmark cannot
# read the pair as a setext heading. That escape is only ever written as one `\<newline>\`
# unit (glue backslash, newline, escape backslash), so it is unescaped only in that exact
# context — a `\--` line anywhere else (fenced code, authored text) is user content and
# stays. Also strips trailing newlines introduced by TipTap/ProseMirror trailing paragraphs.
class Messages::WebhookContentNormalizer
  def self.normalize(text)
    return text if text.blank?

    text.gsub(/(\\\r?\n)\\(?=(?:-+|=+)[ \t]*\r?$)/, '\\1')
        .gsub(/\\\r?\n/, "\n")
        .sub(/(\r?\n)+\z/, '')
  end
end
