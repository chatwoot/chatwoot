# Strips CommonMark hard line breaks from stored markdown source (backslash before newline).
# ProseMirror / the dashboard editor emits this form so soft breaks survive as markdown;
# webhook consumers expect plain newlines without a visible backslash (e.g. WhatsApp gateways).
class Messages::WebhookContentNormalizer
  def self.normalize(text)
    return text if text.blank?

    text.gsub(/\\\r?\n/, "\n")
  end
end
