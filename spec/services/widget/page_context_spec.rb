require 'rails_helper'

RSpec.describe Widget::PageContext, type: :service do
  let(:conversation) do
    create(:conversation, additional_attributes: {
             'referer' => 'https://referrer.example/source',
             'browser_language' => 'en'
           })
  end
  let(:page_context) do
    {
      url: ' https://Example.com/help?secret=value#article ',
      title: 'Help article',
      tab_id: 'tab-one',
      sequence: 2
    }
  end

  describe '.normalize' do
    it 'normalizes the URL and returns only the supported fields' do
      normalized_page = described_class.normalize(page_context.merge(ignored: 'discarded', updated_at: 'client-value'))

      expect(normalized_page).to include(
        'url' => 'https://example.com/help',
        'title' => 'Help article',
        'tab_id' => 'tab-one',
        'sequence' => 2
      )
      expect(normalized_page['updated_at']).not_to eq('client-value')
      expect { Time.iso8601(normalized_page['updated_at']) }.not_to raise_error
    end

    it 'rejects credentials and non-http URLs' do
      expect do
        described_class.normalize(page_context.merge(url: 'https://user:password@example.com/help'))
      end.to raise_error(described_class::InvalidError)

      expect do
        described_class.normalize(page_context.merge(url: 'javascript:alert(1)'))
      end.to raise_error(described_class::InvalidError)
    end

    it 'rejects values outside the field bounds' do
      expect do
        described_class.normalize(page_context.merge(title: 't' * (described_class::TITLE_MAX_LENGTH + 1)))
      end.to raise_error(described_class::InvalidError)

      expect do
        described_class.normalize(page_context.merge(tab_id: 't' * (described_class::TAB_ID_MAX_LENGTH + 1)))
      end.to raise_error(described_class::InvalidError)

      expect do
        described_class.normalize(page_context.merge(sequence: described_class::MAX_SEQUENCE + 1))
      end.to raise_error(described_class::InvalidError)
    end
  end

  describe '#perform' do
    it 'merges the current page, preserves existing attributes, and writes updated_at' do
      conversation.update_column(:updated_at, 1.hour.ago)
      previous_updated_at = conversation.reload.updated_at

      expect(described_class.new(conversation: conversation, current_page: page_context).perform).to be(true)

      conversation.reload
      expect(conversation.additional_attributes).to include(
        'referer' => 'https://referrer.example/source',
        'browser_language' => 'en'
      )
      expect(conversation.additional_attributes['current_page']).to include(
        'url' => 'https://example.com/help',
        'title' => 'Help article',
        'tab_id' => 'tab-one',
        'sequence' => 2
      )
      expect(conversation.additional_attributes['current_page']['updated_at']).to be_present
      expect(conversation.updated_at).to be > previous_updated_at
    end

    it 'ignores a stale or equal sequence for the same tab' do
      conversation.update!(additional_attributes: conversation.additional_attributes.merge(
        'current_page' => {
          'url' => 'https://example.com/newer',
          'title' => 'Newer',
          'tab_id' => 'tab-one',
          'sequence' => 2
        }
      ))
      conversation.update_column(:updated_at, 1.hour.ago)
      previous_attributes = conversation.reload.additional_attributes
      previous_updated_at = conversation.updated_at

      stale_page = page_context.merge(url: 'https://example.com/older', sequence: 2)
      expect(described_class.new(conversation: conversation, current_page: stale_page).perform).to be(false)

      expect(conversation.reload.additional_attributes).to eq(previous_attributes)
      expect(conversation.updated_at).to eq(previous_updated_at)
    end

    it 'uses last-arrival behavior when updates come from different tabs' do
      conversation.update!(additional_attributes: conversation.additional_attributes.merge(
        'current_page' => {
          'url' => 'https://example.com/tab-a',
          'title' => 'Tab A',
          'tab_id' => 'tab-a',
          'sequence' => 100
        }
      ))

      tab_b_page = page_context.merge(url: 'https://example.com/tab-b', tab_id: 'tab-b', sequence: 1)
      expect(described_class.new(conversation: conversation, current_page: tab_b_page).perform).to be(true)
      expect(conversation.reload.additional_attributes['current_page']['tab_id']).to eq('tab-b')

      tab_a_page = page_context.merge(url: 'https://example.com/tab-a-later', tab_id: 'tab-a', sequence: 2)
      expect(described_class.new(conversation: conversation, current_page: tab_a_page).perform).to be(true)
      expect(conversation.reload.additional_attributes['current_page']).to include(
        'url' => 'https://example.com/tab-a-later',
        'tab_id' => 'tab-a',
        'sequence' => 2
      )
      expect(conversation.reload.additional_attributes['current_page']['updated_at']).to be_present
    end
  end
end
