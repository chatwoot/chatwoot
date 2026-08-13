require 'rails_helper'

# Regression coverage for a crash where `content_attributes.items` being blank or malformed
# (nil, a String, ...) raised NoMethodError from inside the validator instead of producing a
# normal ActiveModel validation error. See app/models/concerns/content_attribute_validator.rb.
RSpec.describe ContentAttributeValidator, type: :validator do
  # Each content_type only allows a different set of item keys (see the ALLOWED_*_KEYS constants),
  # so the "well-formed" fixture has to match the content_type under test.
  valid_item_by_content_type = {
    'input_select' => { title: 'a', value: 'a' },
    'cards' => { title: 'a', description: 'd', media_url: 'https://example.com/a.png',
                 actions: [{ text: 'Go', type: 'link', uri: 'https://example.com' }] },
    'form' => { type: 'text', label: 'Name', name: 'name' },
    'article' => { title: 'a', description: 'd', link: 'https://example.com' }
  }.freeze

  %w[input_select cards form article].each do |content_type|
    context "when content_type is #{content_type}" do
      it 'is valid with well-formed items' do
        message = build(:message, content_type: content_type, content_attributes: { items: [valid_item_by_content_type.fetch(content_type)] })

        message.valid?

        expect(message.errors[:content_attributes]).to be_empty
      end

      it 'does not raise and adds an error when items is missing entirely' do
        message = build(:message, content_type: content_type, content_attributes: {})

        expect { message.valid? }.not_to raise_error
        expect(message.errors[:content_attributes]).to include('At least one item is required.')
      end

      it 'does not raise and adds an error when items is explicitly nil' do
        message = build(:message, content_type: content_type, content_attributes: { items: nil })

        expect { message.valid? }.not_to raise_error
        expect(message.errors[:content_attributes]).to include('At least one item is required.')
      end

      it 'does not raise and adds an error when items is a String' do
        message = build(:message, content_type: content_type, content_attributes: { items: 'not-an-array' })

        expect { message.valid? }.not_to raise_error
        expect(message.errors[:content_attributes]).to include('Items should be a hash.')
      end

      it 'does not raise and adds an error when items contains non-hash entries' do
        message = build(:message, content_type: content_type, content_attributes: { items: ['not-a-hash'] })

        expect { message.valid? }.not_to raise_error
        expect(message.errors[:content_attributes]).to include('Items should be a hash.')
      end

      it 'does not run per-item validation (which itself assumes an array of hashes) when items is invalid' do
        message = build(:message, content_type: content_type, content_attributes: { items: nil })

        message.valid?

        # A single, clear "items required" error -- not also a NoMethodError-triggered crash and
        # not a confusing second "invalid keys" error computed against a blank items list.
        expect(message.errors[:content_attributes]).to eq(['At least one item is required.'])
      end
    end
  end

  context 'when content_type is cards and items are present but missing actions' do
    it 'still runs the cards-specific action validation' do
      message = build(:message, content_type: 'cards', content_attributes: { items: [{ title: 'a' }] })

      message.valid?

      expect(message.errors[:content_attributes]).to include('contains items missing actions')
    end
  end

  context 'when content_type does not require items (e.g. text)' do
    it 'is valid regardless of content_attributes' do
      message = build(:message, content_type: 'text', content_attributes: {})

      expect { message.valid? }.not_to raise_error
      expect(message.errors[:content_attributes]).to be_empty
    end
  end
end
