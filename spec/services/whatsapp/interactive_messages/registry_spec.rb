require 'rails_helper'

RSpec.describe Whatsapp::InteractiveMessages::Registry do
  it 'exposes only interaction types with implemented adapters' do
    expect(described_class.implemented_types).to eq(['button'])
    expect(described_class).to be_implemented('button')
    expect(described_class).not_to be_implemented('list')
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
end
