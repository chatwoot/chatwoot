# Strips CommonMark hard line breaks from stored markdown source (backslash before newline).
# ProseMirror / the dashboard editor emits this form so soft breaks survive as markdown;
# webhook consumers expect plain newlines without a visible backslash (e.g. WhatsApp gateways).
# The editor also escapes a `-`/`--`/`==` line under a hard break as `\--` so cmark cannot
# read the pair as a setext heading; markdown renderers show it as `--`, so webhook consumers
# get the unescaped form too. Fenced code blocks are skipped entirely: backslashes there are
# literal user content, not editor artifacts. Also strips trailing newlines introduced by
# TipTap/ProseMirror trailing paragraph nodes.
class Messages::WebhookContentNormalizer
  FENCE_OPENING = /\A {0,3}(`{3,}|~{3,})/

  def self.normalize(text)
    return text if text.blank?

    strip_editor_artifacts(text).sub(/(\r?\n)+\z/, '')
  end

  def self.strip_editor_artifacts(text)
    closing_fence = nil
    text.each_line.map do |line|
      if closing_fence
        closing_fence = nil if line.match?(closing_fence)
        line
      elsif (fence = line[FENCE_OPENING, 1])
        closing_fence = /\A {0,3}#{fence[0]}{#{fence.length},}[ \t]*\r?\n?\z/
        line
      else
        line.gsub(/\\\r?\n/, "\n").sub(/\A\\(?=(?:-+|=+)[ \t]*\r?$)/, '')
      end
    end.join
  end
  private_class_method :strip_editor_artifacts
end
