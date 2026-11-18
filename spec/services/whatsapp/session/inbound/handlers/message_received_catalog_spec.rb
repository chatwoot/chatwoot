require 'rails_helper'

# Catalog products and orders as the connector publishes them (#426, #422), from payloads
# captured on a live WhatsApp session with the sender swapped for the contract's examples.
# What an agent reads is the row's text (conversation list, search, notifications) and the
# card drawn from content_attributes, so both are asserted here.
RSpec.describe Whatsapp::Session::Inbound::Handlers::MessageReceived do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }
  let(:model) { Whatsapp::Session::Model }

  before do
    allow(channel).to receive(:provider_service).and_return(backend)
    inbox.account.update!(locale: 'pt_BR')
  end

  def payload(name)
    JSON.parse(Rails.root.join('spec/fixtures/whatsapp/session/catalog', "#{name}.json").read)
  end

  def deliver(message)
    inbound = model::InboundMessage.from_h(message)
    event = model::Event.build(model::Events::MessageReceived.new(message: inbound), epoch: 1, seq: 1)
    Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event)
    inbox.messages.find_by!(source_id: message['id'])
  end

  # The job runs in Sidekiq, whose locale is the installation's default and not the
  # account's: a row written there in English is a pt_BR agent reading "3 items".
  around { |example| I18n.with_locale(:en) { example.run } }

  describe 'a product sent from the catalog' do
    it 'keeps the whole product, not only the title and body the card used to carry' do
      message = deliver(payload('product_received'))

      expect(message.message_type).to eq('incoming')
      expect(message.content_attributes['is_unsupported']).to be_nil
      expect(message.content_attributes.dig('rich', 'product')).to include(
        'id' => '1000000000000001', 'title' => 'Caneca', 'description' => 'Caneca de cerâmica, 300 ml',
        'price_1000' => 34_900, 'currency' => 'BRL', 'owner' => { 'kind' => 'lid', 'id' => '918273645546372' },
        'thumbnail' => start_with('data:image/jpeg')
      )
    end

    it 'writes the price in the account language, from thousandths' do
      expect(deliver(payload('product_received')).content).to eq("Caneca\n\nR$ 34,90\n\nCaneca de cerâmica, 300 ml")
    end

    it 'follows an English account too' do
      inbox.account.update!(locale: 'en')

      expect(deliver(payload('product_received')).content).to include('R$34.90')
    end

    it 'writes the sale price, which is the one the customer pays' do
      message = payload('product_received')
      message['content']['product'].merge!('price_1000' => 59_900, 'sale_price_1000' => 49_900)

      content = deliver(message).content
      expect(content).to include('R$ 49,90')
      expect(content).not_to include('R$ 59,90')
    end

    it 'never writes a missing price as zero' do
      message = payload('product_received')
      message['content']['product'].except!('price_1000', 'sale_price_1000', 'currency')

      content = deliver(message).content
      expect(content).to start_with('Caneca')
      expect(content).not_to include('0,00')
    end

    it 'says there is a catalog product when WhatsApp sent nothing readable about it' do
      message = payload('product_received')
      message['content'] = { 'type' => 'rich', 'kind' => 'product', 'product' => {} }

      row = deliver(message)
      expect(row.content).to eq('Mensagem com um produto do catálogo. Veja no WhatsApp.')
      expect(row.content_attributes['is_unsupported']).to be_nil
      expect(row.content_attributes.dig('rich', 'product')).to eq({})
    end

    it 'keeps what WhatsApp sent of a product that came without a name' do
      message = payload('product_received')
      message['content']['product'].delete('title')

      content = deliver(message).content
      expect(content).to end_with("34,90\n\nCaneca de cerâmica, 300 ml")
      expect(content).not_to include('Mensagem com um produto')
    end

    it 'writes a currency with three decimals as three, the way the card shows it' do
      message = payload('product_received')
      message['content']['product'].merge!('price_1000' => 1234, 'currency' => 'KWD')

      expect(deliver(message).content).to include('KWD 1,234')
    end

    it 'writes a currency without decimals without them' do
      message = payload('product_received')
      message['content']['product'].merge!('price_1000' => 1_500_000, 'currency' => 'JPY')

      expect(deliver(message).content).to include('JPY 1.500')
    end

    it 'files the business own product as an outgoing message' do
      message = deliver(payload('product_sent'))

      expect(message.message_type).to eq('outgoing')
      expect(message.content).to start_with("Camiseta básica\n\nR$ 59,90")
      expect(message.content_attributes.dig('rich', 'product', 'price_1000')).to eq(59_900)
    end
  end

  describe 'a question asked from a catalog product' do
    it 'keeps the product the message quotes and does not look for a message by its id' do
      message = deliver(payload('product_quoted'))

      expect(message.content).to eq('Aceita Pix?')
      expect(message.content_attributes['quoted_product']).to include(
        'title' => 'Caneca', 'price_1000' => 34_900, 'currency' => 'BRL'
      )
      # quoted_id is product_inquiry_<id>, which names no message: following it would draw
      # a "quoted message not found" box over every question asked from the catalog.
      expect(message.content_attributes).not_to have_key('in_reply_to_external_id')
    end

    it 'keeps an unreadable quoted product as one, so the bubble still says it is there' do
      message = payload('product_quoted')
      message['quoted_product'] = {}

      expect(deliver(message).content_attributes['quoted_product']).to eq({})
    end
  end

  describe 'an order placed from the catalog' do
    it 'writes the order the way WhatsApp shows it, in the account language' do
      content = deliver(payload('order_received')).content

      expect(content).to eq(<<~TEXT.strip)
        Pedido 2000000000000001
        3 itens · R$ 129,70 (total estimado)

        • Camiseta básica × 1 · R$ 59,90
        • Caneca × 2 · R$ 34,90
      TEXT
    end

    it 'never shows the connector fallback text' do
      content = deliver(payload('order_received')).content

      expect(content).not_to include('3 items')
      expect(content).not_to include('estimated total')
    end

    it 'keeps the whole order on the row' do
      message = deliver(payload('order_received'))

      expect(message.content_attributes['is_unsupported']).to be_nil
      order = message.content_attributes.dig('rich', 'order')
      expect(order).to include('id' => '2000000000000001', 'item_count' => 3, 'total_1000' => 129_700, 'currency' => 'BRL')
      expect(order['items'].map { |item| item.slice('name', 'quantity', 'price_1000') }).to eq(
        [{ 'name' => 'Camiseta básica', 'quantity' => 1, 'price_1000' => 59_900 },
         { 'name' => 'Caneca', 'quantity' => 2, 'price_1000' => 34_900 }]
      )
    end

    it 'writes the summary alone when the items could not be fetched' do
      message = payload('order_received')
      message['content']['order'].delete('items')

      row = deliver(message)
      expect(row.content).to eq("Pedido 2000000000000001\n3 itens · R$ 129,70 (total estimado)")
      expect(row.content_attributes.dig('rich', 'order', 'total_1000')).to eq(129_700)
    end

    it 'keeps the note the customer wrote with the order' do
      message = payload('order_received')
      message['content']['body'] = 'Pode entregar amanhã?'

      expect(deliver(message).content).to include("(total estimado)\n\nPode entregar amanhã?\n\n• Camiseta")
    end

    it 'leaves out a total and an item price WhatsApp did not prove, instead of writing zero' do
      message = payload('order_received')
      message['content']['order'].delete('total_1000')
      message['content']['order']['items'][1].delete('price_1000')

      content = deliver(message).content
      expect(content).to include("Pedido 2000000000000001\n3 itens\n")
      expect(content).to end_with('• Caneca × 2')
      expect(content).not_to include('R$ 0,00')
    end

    it 'prices an item in the order currency when the item names none' do
      message = payload('order_received')
      message['content']['order']['items'][0].delete('currency')

      expect(deliver(message).content).to include('× 1 · R$ 59,90')
    end

    it 'names the variant the customer chose' do
      message = payload('order_received')
      message['content']['order']['items'][0]['variant'] = 'Tamanho: M'

      expect(deliver(message).content).to include('• Camiseta básica (Tamanho: M) × 1')
    end

    it 'counts the units of the items when the summary has no count' do
      message = payload('order_received')
      message['content']['order'].delete('item_count')

      expect(deliver(message).content).to include("Pedido 2000000000000001\n3 itens ·")
    end

    it 'writes one item in the singular' do
      message = payload('order_received')
      message['content']['order']['item_count'] = 1
      message['content']['order'].delete('items')

      expect(deliver(message).content).to include('1 item ·')
    end
  end
end
