# Strips CommonMark hard line breaks from stored markdown source (backslash before newline).
# ProseMirror / the dashboard editor emits this form so soft breaks survive as markdown;
# webhook consumers expect plain newlines without a visible backslash (e.g. WhatsApp gateways).
# The editor also escapes a `-`/`--`/`==` line under a hard break as `\--` so cmark cannot
# read the pair as a setext heading; markdown renderers show it as `--`, so webhook consumers
# get the unescaped form too. Also strips trailing newlines introduced by TipTap/ProseMirror
# trailing paragraph nodes.
class Messages::WebhookContentNormalizer
  def self.normalize(text)
    return text if text.blank?

    text.gsub(/\\\r?\n/, "\n")
        .gsub(/^\\(?=(?:-+|=+)[ \t]*\r?$)/, '')
        .sub(/(\r?\n)+\z/, '')
  end
end
