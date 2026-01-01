# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/support/shared_examples/aloo/embeddable')

RSpec.describe Aloo::Memory do
  subject(:memory) { build(:aloo_memory) }

  describe 'concerns' do
    it 'includes AccountScoped' do
      expect(described_class.ancestors).to include(Aloo::AccountScoped)
    end

    it 'includes Embeddable' do
      expect(described_class.ancestors).to include(Aloo::Embeddable)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:assistant).class_name('Aloo::Assistant') }
    it { is_expected.to belong_to(:contact).optional }
    it { is_expected.to belong_to(:conversation).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:memory_type).in_array(described_class::MEMORY_TYPES) }
    it { is_expected.to validate_presence_of(:content) }
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_memory) { create(:aloo_memory, confidence: 0.5) }
      let!(:inactive_memory) { create(:aloo_memory, :low_confidence) }

      it 'returns memories with confidence above threshold' do
        expect(described_class.active).to include(active_memory)
        expect(described_class.active).not_to include(inactive_memory)
      end
    end

    describe '.by_type' do
      let!(:preference) { create(:aloo_memory, :preference) }
      let!(:faq) { create(:aloo_memory, :faq) }

      it 'filters by memory type' do
        expect(described_class.by_type('preference')).to include(preference)
        expect(described_class.by_type('preference')).not_to include(faq)
      end
    end

    describe '.for_contact' do
      let(:contact) { create(:contact) }
      let!(:contact_memory) { create(:aloo_memory, :preference, contact: contact) }
      let!(:other_memory) { create(:aloo_memory, :preference) }

      it 'filters by contact' do
        expect(described_class.for_contact(contact.id)).to include(contact_memory)
        expect(described_class.for_contact(contact.id)).not_to include(other_memory)
      end
    end

    describe '.contact_scoped' do
      let!(:preference) { create(:aloo_memory, :preference) }
      let!(:faq) { create(:aloo_memory, :faq) }

      it 'returns contact-scoped memory types' do
        expect(described_class.contact_scoped).to include(preference)
        expect(described_class.contact_scoped).not_to include(faq)
      end
    end

    describe '.global_scoped' do
      let!(:preference) { create(:aloo_memory, :preference) }
      let!(:faq) { create(:aloo_memory, :faq) }

      it 'returns global memory types' do
        expect(described_class.global_scoped).not_to include(preference)
        expect(described_class.global_scoped).to include(faq)
      end
    end

    describe '.with_entity' do
      let!(:with_entity) { create(:aloo_memory, :with_entities) }
      let!(:without_entity) { create(:aloo_memory, entities: []) }

      it 'filters by entity' do
        expect(described_class.with_entity('product_name')).to include(with_entity)
        expect(described_class.with_entity('product_name')).not_to include(without_entity)
      end
    end

    describe '.with_topic' do
      let!(:with_topic) { create(:aloo_memory, :with_topics) }
      let!(:without_topic) { create(:aloo_memory, topics: []) }

      it 'filters by topic' do
        expect(described_class.with_topic('billing')).to include(with_topic)
        expect(described_class.with_topic('billing')).not_to include(without_topic)
      end
    end
  end

  describe '#contact_scoped?' do
    it 'returns true for preference type' do
      memory.memory_type = 'preference'
      expect(memory.contact_scoped?).to be true
    end

    it 'returns false for faq type' do
      memory.memory_type = 'faq'
      expect(memory.contact_scoped?).to be false
    end

    it 'returns true for commitment type' do
      memory.memory_type = 'commitment'
      expect(memory.contact_scoped?).to be true
    end

    it 'returns false for procedure type' do
      memory.memory_type = 'procedure'
      expect(memory.contact_scoped?).to be false
    end
  end

  describe '#global_scoped?' do
    it 'returns false for preference type' do
      memory.memory_type = 'preference'
      expect(memory.global_scoped?).to be false
    end

    it 'returns true for faq type' do
      memory.memory_type = 'faq'
      expect(memory.global_scoped?).to be true
    end
  end

  describe '#record_observation!' do
    let(:memory) { create(:aloo_memory, observation_count: 1, confidence: 0.5) }

    it 'increments observation count' do
      expect { memory.record_observation! }.to change { memory.observation_count }.by(1)
    end

    it 'updates last_observed_at' do
      freeze_time do
        memory.record_observation!
        expect(memory.last_observed_at).to eq(Time.current)
      end
    end

    it 'increases confidence' do
      expect { memory.record_observation! }.to change { memory.confidence }.from(0.5).to(0.55)
    end

    it 'caps confidence at 1.0' do
      memory.update!(confidence: 0.98)
      memory.record_observation!
      expect(memory.confidence).to eq(1.0)
    end
  end

  describe '#record_feedback!' do
    context 'when helpful' do
      let(:memory) { create(:aloo_memory, helpful_count: 0, confidence: 0.5) }

      it 'increments helpful_count' do
        expect { memory.record_feedback!(helpful: true) }.to change { memory.helpful_count }.by(1)
      end

      it 'increases confidence' do
        expect { memory.record_feedback!(helpful: true) }.to change { memory.confidence }.from(0.5).to(0.6)
      end

      it 'caps confidence at 1.0' do
        memory.update!(confidence: 0.95)
        memory.record_feedback!(helpful: true)
        expect(memory.confidence).to eq(1.0)
      end
    end

    context 'when not helpful' do
      let(:memory) { create(:aloo_memory, not_helpful_count: 0, confidence: 0.5) }

      it 'increments not_helpful_count' do
        expect { memory.record_feedback!(helpful: false) }.to change { memory.not_helpful_count }.by(1)
      end

      it 'decreases confidence' do
        expect { memory.record_feedback!(helpful: false) }.to change { memory.confidence }.from(0.5).to(0.35)
      end

      it 'floors confidence at 0.0' do
        memory.update!(confidence: 0.1)
        memory.record_feedback!(helpful: false)
        expect(memory.confidence).to eq(0.0)
      end

      it 'flags for review when threshold reached' do
        # The flagged_for_review check happens before increment, so we need >= 3 before the call
        memory.update!(not_helpful_count: 3)
        memory.record_feedback!(helpful: false)
        expect(memory.flagged_for_review).to be true
      end
    end
  end

  describe '#ranking_score' do
    let(:memory) { create(:aloo_memory, confidence: 0.7, observation_count: 1) }

    it 'calculates combined ranking score' do
      allow(Aloo::RankingConfig).to receive(:calculate_score).and_return(0.85)

      score = memory.ranking_score(query_similarity: 0.9)

      expect(Aloo::RankingConfig).to have_received(:calculate_score).with(
        similarity: 0.9,
        confidence: memory.confidence,
        observation_count: memory.observation_count,
        last_observed_at: memory.last_observed_at,
        query_type_boost: nil,
        memory_type: memory.memory_type
      )
      expect(score).to eq(0.85)
    end

    it 'applies query type boost when matching' do
      allow(Aloo::RankingConfig).to receive(:calculate_score).and_return(0.9)

      memory.ranking_score(query_similarity: 0.9, query_type_boost: 'preference')

      expect(Aloo::RankingConfig).to have_received(:calculate_score).with(
        hash_including(query_type_boost: 'preference')
      )
    end
  end

  describe '#to_context_format' do
    context 'when contact-scoped' do
      it 'formats with scope and type labels' do
        memory.memory_type = 'preference'
        memory.content = 'Customer prefers email'

        expect(memory.to_context_format).to eq('[Personal] [Preference] Customer prefers email')
      end
    end

    context 'when global-scoped' do
      it 'formats with general scope label' do
        memory.memory_type = 'faq'
        memory.content = 'Return policy is 30 days'

        expect(memory.to_context_format).to eq('[General] [Faq] Return policy is 30 days')
      end
    end
  end

  describe '#embedding_content' do
    it 'returns source_excerpt when present' do
      memory.source_excerpt = 'Source excerpt text'
      memory.content = 'Full content'

      expect(memory.embedding_content).to eq('Source excerpt text')
    end

    it 'returns content when source_excerpt is blank' do
      memory.source_excerpt = nil
      memory.content = 'Full content'

      expect(memory.embedding_content).to eq('Full content')
    end
  end
end
