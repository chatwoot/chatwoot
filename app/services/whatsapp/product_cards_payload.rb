# Session media carousel (2..10 cards); one item uses an image CTA URL message.
class Whatsapp::ProductCardsPayload
  def self.build(attributes)
    new(attributes).build
  end

  def initialize(attributes)
    @attributes = attributes
  end

  def build
    raise ArgumentError, 'Invalid product cards' unless @attributes.is_a?(Hash)

    items = @attributes['items']
    raise ArgumentError, 'Invalid product count' unless items.is_a?(Array) && items.length.between?(1, 10)

    body = valid_text(@attributes['body'], 1024)
    cards = items.each_with_index.map { |item, index| card(item, index) }
    return cards.first.except(:card_index).merge(body: { text: valid_text("#{body}\n#{items.first['body']}", 1024) }) if cards.one?

    { type: 'carousel', body: { text: body }, action: { cards: cards } }
  end

  private

  def card(item, index)
    raise ArgumentError, 'Invalid product card' unless item.is_a?(Hash)

    text = valid_text(item['body'], 160)
    raise ArgumentError, 'Too many line breaks' if text.count("\n") > 2

    {
      card_index: index, type: 'cta_url',
      header: { type: 'image', image: { link: valid_url(item['image_url']) } },
      body: { text: text },
      action: { name: 'cta_url', parameters: { display_text: 'Ver produto', url: valid_url(item['url']) } }
    }
  end

  def valid_text(value, limit)
    raise ArgumentError, 'Invalid card text' unless value.is_a?(String) && value.strip.present? && value.length <= limit

    value
  end

  def valid_url(value)
    uri = URI.parse(value.to_s)
    raise ArgumentError, 'Invalid card URL' unless uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?

    value
  rescue URI::InvalidURIError
    raise ArgumentError, 'Invalid card URL'
  end
end
