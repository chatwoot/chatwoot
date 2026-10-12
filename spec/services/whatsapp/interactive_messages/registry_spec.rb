require 'rails_helper'

RSpec.describe Whatsapp::InteractiveMessages::Registry do
  it 'exposes only interaction types with implemented adapters' do
    expect(described_class.implemented_types).to eq(%w[button list cta_url])
    expect(described_class).to be_implemented('button')
    expect(described_class).to be_implemented('list')
    expect(described_class).to be_implemented('cta_url')
  end

  describe '.resolve' do
    let(:payload) do
      {
        schema_version: 1,
        type: 'button',
        body: { text: 'Please choose one option.' },
        action: { buttons: [{ title: 'Confirm' }, { title: 'Change' }] }
      }
    end

    it 'produces the canonical persisted snapshot with fresh server delivery IDs' do
      allow(SecureRandom).to receive(:uuid).and_return(
        '00000000-0000-4000-8000-000000000001',
        '00000000-0000-4000-8000-000000000002'
      )
      expected = JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/button.json').read)

      expect(described_class.resolve(payload)).to eq(expected)
    end

    it 'rejects unknown fields and client-owned technical IDs' do
      payload[:action][:buttons].first[:delivery_id] = 'client-id'

      expect { described_class.resolve(payload) }
        .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /unsupported fields: delivery_id/)
    end

    it 'retains optional text headers and footers at the exact limits' do
      payload[:body][:text] = 'x' * 1024
      payload[:header] = { type: 'text', text: 'h' * 60 }
      payload[:footer] = { text: 'f' * 60 }
      payload[:action][:buttons] = Array.new(3) { |index| { title: index.to_s * 20 } }
      snapshot = described_class.resolve(payload)

      expect(snapshot['header']).to eq('type' => 'text', 'text' => 'h' * 60)
      expect(snapshot['footer']).to eq('text' => 'f' * 60)
      expect(described_class.provider_payload(snapshot)).to include(
        header: { type: 'text', text: 'h' * 60 }, footer: { text: 'f' * 60 }
      )
    end

    %w[image video document].each do |type|
      it "accepts a transient #{type} header without client attachment identifiers" do
        payload[:header] = { type: type }
        expect(described_class.resolve(payload)['header']).to eq('type' => type)

        payload[:header][:attachment_id] = 123
        expect { described_class.resolve(payload) }.to raise_error(Whatsapp::InteractiveMessages::ValidationError, /attachment_id/)
      end
    end

    it 'rejects malformed header/footer shapes and blank or overflowing visible fields' do
      invalid_fields = [
        { header: nil }, { header: { type: 'audio' } }, { header: { type: 'text', text: ' ' } },
        { header: { type: 'text', text: 'h' * 61 } }, { header: { type: 'image', link: 'https://example.com/image' } },
        { footer: { text: 'f' * 61 } }, { footer: { text: '' } }, { footer: { text: 'ok', unknown: true } },
        { body: { text: 'x' * 1025 } }
      ]
      invalid_fields.each do |fields|
        expect { described_class.resolve(payload.merge(fields)) }.to raise_error(Whatsapp::InteractiveMessages::ValidationError)
      end
    end

    it 'rejects unknown versions and raw provider payload fields' do
      payload[:schema_version] = 2
      payload[:interactive] = { type: 'button' }

      expect { described_class.resolve(payload) }
        .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /unsupported fields: interactive/)
    end

    it 'rejects blank, duplicate, long, and excessive button content' do
      invalid_payloads = [
        payload.deep_dup.tap { |value| value[:body][:text] = '' },
        payload.deep_dup.tap { |value| value[:action][:buttons][1][:title] = 'Confirm' },
        payload.deep_dup.tap { |value| value[:action][:buttons][0][:title] = 'x' * 21 },
        payload.deep_dup.tap { |value| value[:action][:buttons] << { title: 'Third' } << { title: 'Fourth' } }
      ]

      invalid_payloads.each do |invalid_payload|
        expect { described_class.resolve(invalid_payload) }.to raise_error(Whatsapp::InteractiveMessages::ValidationError)
      end
    end
  end

  describe '.provider_payload' do
    it 'maps the canonical fixture to the native Meta request shape' do
      snapshot = JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/button.json').read)

      expect(described_class.provider_payload(snapshot)).to eq(
        type: 'button',
        body: { text: 'Please choose one option.' },
        action: {
          buttons: [
            { type: 'reply', reply: { id: 'reply_00000000-0000-4000-8000-000000000001', title: 'Confirm' } },
            { type: 'reply', reply: { id: 'reply_00000000-0000-4000-8000-000000000002', title: 'Change' } }
          ]
        }
      )
    end
  end

  describe 'native lists' do
    let(:payload) do
      {
        schema_version: 1,
        type: 'list',
        header: { type: 'text', text: 'Available meals' },
        body: { text: 'Choose a meal.' },
        footer: { text: 'One selection per order.' },
        action: {
          button: 'View meals',
          sections: [
            { title: 'Lunch', rows: [{ title: 'Pasta', description: 'Tomato and basil' }, { title: 'Salad' }] }
          ]
        }
      }
    end

    it 'resolves the canonical snapshot with unique server-owned row IDs' do
      allow(SecureRandom).to receive(:uuid).and_return(
        '00000000-0000-4000-8000-000000000001',
        '00000000-0000-4000-8000-000000000002'
      )

      expect(described_class.resolve(payload)).to eq(
        JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/list.json').read)
      )
    end

    it 'accepts every exact list boundary and publishes the limits' do
      payload[:body][:text] = 'b' * 4096
      payload[:header][:text] = 'h' * 60
      payload[:footer][:text] = 'f' * 60
      payload[:action][:button] = 'o' * 20
      payload[:action][:sections] = Array.new(10) do |index|
        { title: index.to_s * 24, rows: [{ title: index.to_s * 24, description: 'd' * 72 }] }
      end

      snapshot = described_class.resolve(payload)
      expect(snapshot.dig('action', 'sections').sum { |section| section['rows'].length }).to eq(10)
      expect(snapshot.dig('action', 'sections').flat_map { |section| section['rows'] }.pluck('delivery_id').uniq.length).to eq(10)
      expect(described_class.limits_for('list')).to eq(
        body_max_length: 4096,
        header_max_length: 60,
        footer_max_length: 60,
        button_max_length: 20,
        section_min_count: 1,
        section_max_count: 10,
        row_min_count: 1,
        row_max_count: 10,
        section_title_max_length: 24,
        row_title_max_length: 24,
        row_description_max_length: 72
      )
    end

    it 'rejects empty collections and every documented overflow' do
      invalid_payloads = [
        payload.deep_dup.tap { |value| value[:body][:text] = '' },
        payload.deep_dup.tap { |value| value[:body][:text] = 'b' * 4097 },
        payload.deep_dup.tap { |value| value[:header][:text] = 'h' * 61 },
        payload.deep_dup.tap { |value| value[:footer][:text] = 'f' * 61 },
        payload.deep_dup.tap { |value| value[:action][:button] = 'o' * 21 },
        payload.deep_dup.tap { |value| value[:action][:sections] = [] },
        payload.deep_dup.tap { |value| value[:action][:sections] = Array.new(11) { { rows: [{ title: 'Row' }] } } },
        payload.deep_dup.tap { |value| value[:action][:sections] = [{ rows: [] }] },
        payload.deep_dup.tap { |value| value[:action][:sections] = [{ rows: Array.new(11) { { title: 'Row' } } }] },
        payload.deep_dup.tap { |value| value[:action][:sections][0][:title] = 's' * 25 },
        payload.deep_dup.tap { |value| value[:action][:sections][0][:rows][0][:title] = 'r' * 25 },
        payload.deep_dup.tap { |value| value[:action][:sections][0][:rows][0][:description] = 'd' * 73 }
      ]

      invalid_payloads.each do |invalid_payload|
        expect { described_class.resolve(invalid_payload) }.to raise_error(Whatsapp::InteractiveMessages::ValidationError)
      end
    end

    it 'rejects unsupported fields, raw provider shapes, and client row IDs' do
      invalid_payloads = [
        payload.deep_dup.tap { |value| value[:unknown] = true },
        payload.deep_dup.tap { |value| value[:action][:unknown] = true },
        payload.deep_dup.tap { |value| value[:action][:sections][0][:unknown] = true },
        payload.deep_dup.tap { |value| value[:action][:sections][0][:rows][0][:delivery_id] = 'client-id' },
        payload.deep_dup.tap { |value| value[:header][:link] = 'https://example.test/header' }
      ]

      invalid_payloads.each do |invalid_payload|
        expect { described_class.resolve(invalid_payload) }
          .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /unsupported fields/)
      end
    end

    it 'maps the canonical snapshot to a native Cloud list object' do
      snapshot = JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/list.json').read)

      expect(described_class.provider_payload(snapshot)).to eq(
        type: 'list',
        header: { type: 'text', text: 'Available meals' },
        body: { text: 'Choose a meal.' },
        footer: { text: 'One selection per order.' },
        action: {
          button: 'View meals',
          sections: [
            {
              title: 'Lunch',
              rows: [
                { id: 'row_00000000-0000-4000-8000-000000000001', title: 'Pasta', description: 'Tomato and basil' },
                { id: 'row_00000000-0000-4000-8000-000000000002', title: 'Salad' }
              ]
            }
          ]
        }
      )
    end

    it 'rejects invalid stored row IDs instead of contacting the provider' do
      snapshot = JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/list.json').read)
      snapshot.dig('action', 'sections', 0, 'rows', 0)['delivery_id'] = 'x' * 201

      expect { described_class.provider_payload(snapshot) }
        .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /200 characters or fewer/)
    end
  end

  describe 'standalone CTA URLs' do
    let(:payload) do
      {
        schema_version: 1,
        type: 'cta_url',
        header: { type: 'text', text: 'Order update' },
        body: { text: 'Your order is ready to review.' },
        footer: { text: 'Secure link' },
        action: { button: 'View details', url: 'https://example.test/details' }
      }
    end

    it 'resolves the canonical snapshot without click or response identity' do
      snapshot = described_class.resolve(payload)

      expect(snapshot).to eq(JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/cta_url.json').read))
      expect(snapshot.to_json).not_to include('delivery_id', 'preset_option_id', 'uuid')
    end

    it 'accepts every exact visible-content boundary and publishes CTA limits' do
      payload[:body][:text] = 'b' * 1024
      payload[:header][:text] = 'h' * 60
      payload[:footer][:text] = 'f' * 60
      payload[:action][:button] = 'a' * 20

      expect(described_class.resolve(payload).dig('action', 'button')).to eq('a' * 20)
      expect(described_class.limits_for('cta_url')).to eq(
        body_max_length: 1024,
        header_max_length: 60,
        footer_max_length: 60,
        header_types: %w[text image video document],
        button_max_length: 20,
        action_count: 1,
        url_schemes: %w[http https]
      )
    end

    %w[image video document].each do |type|
      it "accepts a transient CTA #{type} header without client attachment identifiers" do
        payload[:header] = { type: type }
        expect(described_class.resolve(payload)['header']).to eq('type' => type)

        payload[:header][:attachment_id] = 123
        expect { described_class.resolve(payload) }
          .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /attachment_id/)
      end
    end

    it 'rejects blank or overflowing content and malformed or unsupported URLs' do
      invalid_payloads = [
        payload.deep_dup.tap { |value| value[:body][:text] = '' },
        payload.deep_dup.tap { |value| value[:body][:text] = 'b' * 1025 },
        payload.deep_dup.tap { |value| value[:header][:text] = 'h' * 61 },
        payload.deep_dup.tap { |value| value[:footer][:text] = 'f' * 61 },
        payload.deep_dup.tap { |value| value[:action][:button] = '' },
        payload.deep_dup.tap { |value| value[:action][:button] = 'a' * 21 },
        payload.deep_dup.tap { |value| value[:action][:url] = '' },
        payload.deep_dup.tap { |value| value[:action][:url] = 'ftp://example.test/details' },
        payload.deep_dup.tap { |value| value[:action][:url] = '/details' },
        payload.deep_dup.tap { |value| value[:action][:url] = 'https://exa mple.test/details' },
        payload.deep_dup.tap { |value| value[:action][:url] = 'https://example..test/details' },
        payload.deep_dup.tap { |value| value[:action][:url] = 'https://.example.test/details' },
        payload.deep_dup.tap { |value| value[:action][:url] = 'https://example.test./details' },
        payload.deep_dup.tap { |value| value[:action][:url] = 'https://999.999.999.999/details' },
        payload.deep_dup.tap { |value| value[:action][:url] = 'https://example.test:65536/details' }
      ]

      invalid_payloads.each do |invalid_payload|
        expect { described_class.resolve(invalid_payload) }.to raise_error(Whatsapp::InteractiveMessages::ValidationError)
      end
    end

    it 'rejects unknown fields, raw provider actions, and multiple actions' do
      invalid_payloads = [
        payload.except(:action),
        payload.deep_dup.tap { |value| value[:action].delete(:url) },
        payload.deep_dup.tap { |value| value[:unknown] = true },
        payload.deep_dup.tap { |value| value[:action][:unknown] = true },
        payload.deep_dup.tap { |value| value[:action] = { name: 'cta_url', parameters: { display_text: 'Open', url: 'https://example.test' } } },
        payload.deep_dup.tap { |value| value[:action] = [value[:action], value[:action]] }
      ]

      invalid_payloads.each do |invalid_payload|
        expect { described_class.resolve(invalid_payload) }.to raise_error(Whatsapp::InteractiveMessages::ValidationError)
      end
    end

    it 'maps the canonical snapshot to Meta native CTA URL shape' do
      snapshot = JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/cta_url.json').read)

      expect(described_class.provider_payload(snapshot)).to eq(
        type: 'cta_url',
        header: { type: 'text', text: 'Order update' },
        body: { text: 'Your order is ready to review.' },
        footer: { text: 'Secure link' },
        action: {
          name: 'cta_url',
          parameters: { display_text: 'View details', url: 'https://example.test/details' }
        }
      )
    end
  end
end
