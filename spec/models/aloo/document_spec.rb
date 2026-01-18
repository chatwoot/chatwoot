# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::Document do
  subject(:document) { build(:aloo_document) }

  describe 'concerns' do
    it 'includes AccountScoped' do
      expect(described_class.ancestors).to include(Aloo::AccountScoped)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:assistant).class_name('Aloo::Assistant') }
    it { is_expected.to have_many(:embeddings).dependent(:destroy) }
    it { is_expected.to have_one_attached(:file) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:source_type).in_array(Aloo::SUPPORTED_SOURCE_TYPES) }

    context 'when status is available' do
      subject { build(:aloo_document, :available, title: nil) }

      it 'validates presence of title' do
        expect(subject).not_to be_valid
        expect(subject.errors[:title]).to include("can't be blank")
      end
    end

    context 'when status is not available' do
      let(:account) { create(:account) }
      let(:assistant) { create(:aloo_assistant, account: account) }

      it 'does not require title' do
        doc = build(:aloo_document, assistant: assistant, account: account, status: :pending, title: nil)
        expect(doc).to be_valid
      end
    end
  end

  describe 'enums' do
    it {
      expect(subject).to define_enum_for(:status)
        .with_values(pending: 0, processing: 1, available: 2, failed: 3, unsupported: 4)
    }
  end

  describe 'scopes' do
    describe '.available' do
      let!(:available_doc) { create(:aloo_document, :available) }
      let!(:pending_doc) { create(:aloo_document, status: :pending) }

      it 'returns only available documents' do
        expect(described_class.available).to include(available_doc)
        expect(described_class.available).not_to include(pending_doc)
      end
    end

    describe '.by_source_type' do
      let!(:file_doc) { create(:aloo_document, source_type: 'file') }
      let!(:website_doc) { create(:aloo_document, :website) }

      it 'filters by source type' do
        expect(described_class.by_source_type('file')).to include(file_doc)
        expect(described_class.by_source_type('file')).not_to include(website_doc)
      end
    end
  end

  describe '#process_async!' do
    let(:document) { create(:aloo_document, status: :pending) }

    it 'updates status to processing' do
      expect { document.process_async! }.to change { document.reload.status }.from('pending').to('processing')
    end

    it 'enqueues ProcessDocumentJob' do
      expect(Aloo::ProcessDocumentJob).to receive(:perform_later).with(document.id)
      document.process_async!
    end
  end

  describe '#mark_failed!' do
    let(:document) { create(:aloo_document, :processing) }

    it 'updates status and error message' do
      document.mark_failed!('Content extraction failed')

      expect(document.status).to eq('failed')
      expect(document.error_message).to eq('Content extraction failed')
    end
  end

  describe '#mark_available!' do
    let(:document) { create(:aloo_document, :processing, error_message: 'Previous error', title: 'Test') }

    it 'updates status and clears error' do
      document.mark_available!

      expect(document.status).to eq('available')
      expect(document.error_message).to be_nil
    end
  end

  describe '#embedded?' do
    context 'when embeddings exist' do
      let(:document) { create(:aloo_document, :available) }

      before do
        create(:aloo_embedding, document: document, assistant: document.assistant, account: document.account)
      end

      it 'returns true' do
        expect(document.embedded?).to be true
      end
    end

    context 'when no embeddings' do
      let(:document) { create(:aloo_document) }

      it 'returns false' do
        expect(document.embedded?).to be false
      end
    end
  end

  describe '#chunk_count' do
    let(:document) { create(:aloo_document, :available) }

    it 'returns count of embeddings' do
      create_list(:aloo_embedding, 3, document: document, assistant: document.assistant, account: document.account)
      expect(document.chunk_count).to eq(3)
    end
  end
end
