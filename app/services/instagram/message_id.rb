require 'base64'

class Instagram::MessageId
  FORMAT = /\A(new_ig_dm_item|ig_dm_item):1:IGMessageID:\d+:\d+:\d+\z/
  ESCAPES = { 'A' => 'Z', 'B' => '/', 'C' => '+', 'D' => '=' }.freeze
  ENCODINGS = ESCAPES.invert.freeze

  def self.aliases(source_id)
    decoded = Base64.strict_decode64(source_id.gsub(/Z([ABCD])/) { ESCAPES.fetch(Regexp.last_match(1)) })
    match = FORMAT.match(decoded)
    return [source_id] unless match && encode(decoded) == source_id

    # Unified Login currently returns new_ig_dm_item from Send API and ig_dm_item
    # in webhooks, with the same account, thread and message identity. Keep both
    # opaque provider IDs intact; only translate these observed format markers.
    prefix = match[1] == 'new_ig_dm_item' ? 'ig_dm_item' : 'new_ig_dm_item'
    [source_id, encode(decoded.sub(match[1], prefix))]
  rescue ArgumentError
    [source_id]
  end

  def self.encode(value)
    Base64.strict_encode64(value).gsub(%r{[Z/+=]}) { |character| "Z#{ENCODINGS.fetch(character)}" }
  end
  private_class_method :encode
end
