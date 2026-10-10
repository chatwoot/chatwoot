require 'rails_helper'

describe Whatsapp::ProductCardsPayload do
  let(:item) do
    { 'body' => "Rack Naturalle\nR$ 950,00 no Pix\nCartão R$ 1.000,00 em até 12x sem juros",
      'image_url' => 'https://cdn.example.com/rack.jpg', 'url' => 'https://www.example.com/rack' }
  end

  it 'builds the exact native media carousel contract with URL buttons' do
    result = described_class.build('body' => 'Veja estas opções:', 'items' => [item, item])
    expect(result).to eq(
      type: 'carousel', body: { text: 'Veja estas opções:' }, action: {
        cards: [0, 1].map do |index|
          { card_index: index, type: 'cta_url', header: { type: 'image', image: { link: item['image_url'] } },
            body: { text: item['body'] }, action: { name: 'cta_url', parameters: { display_text: 'Ver produto', url: item['url'] } } }
        end
      }
    )
  end

  it 'uses an image CTA for one product' do
    result = described_class.build('body' => 'Veja este produto:', 'items' => [item])
    expect(result[:type]).to eq('cta_url')
    expect(result[:header]).to eq(type: 'image', image: { link: item['image_url'] })
    expect(result[:body][:text]).to include(item['body'])
    expect(result).not_to have_key(:card_index)
  end

  it 'rejects unsupported counts and untrusted URL/text shapes' do
    [[], Array.new(11, item), [item.merge('url' => 'http://example.com')], [item.merge('image_url' => 'https://user:secret@example.com')],
     [item.merge('body' => 'x' * 161)], [item.merge('body' => "a\nb\nc\nd")]].each do |items|
      expect { described_class.build('body' => 'Veja:', 'items' => items) }.to raise_error(ArgumentError)
    end
  end
end
