require 'rails_helper'

RSpec.describe Autonomia::Agents::BuildThread do
  let(:account) { create(:account) }
  let(:thread) { described_class.create!(account: account) }

  describe '#build_in_progress? / #build_stale? (E3)' do
    it 'reports an in-progress build right after begin_build!' do
      # Arrange
      thread.begin_build!

      # Act + Assert
      expect(thread.build_in_progress?).to be(true)
      expect(thread.build_stale?).to be(false)
    end

    it 'flips to stale once processing exceeds the job window' do
      # Arrange
      thread.begin_build!

      # Act + Assert
      travel_to((described_class::STALE_PROCESSING_AFTER + 1.minute).from_now) do
        expect(thread.build_stale?).to be(true)
        expect(thread.build_in_progress?).to be(false)
      end
    end

    it 'never reports in-progress outside the processing status' do
      # Arrange
      token = thread.begin_build!
      thread.mark_failed!(token, 'boom')

      # Act + Assert
      expect(thread.build_in_progress?).to be(false)
      expect(thread.build_stale?).to be(false)
    end
  end

  describe '#append_message! dedupe (E4)' do
    it 'no-ops when the same client_message_id is appended twice' do
      # Arrange
      cid = SecureRandom.uuid

      # Act
      thread.append_message!('user', 'olá', client_message_id: cid)
      thread.append_message!('user', 'olá', client_message_id: cid)

      # Assert
      expect(Array(thread.reload.messages).size).to eq(1)
    end

    it 'keeps distinct turns with distinct client_message_ids' do
      # Act
      thread.append_message!('user', 'olá', client_message_id: SecureRandom.uuid)
      thread.append_message!('user', 'olá', client_message_id: SecureRandom.uuid)

      # Assert
      expect(Array(thread.reload.messages).size).to eq(2)
    end
  end
end
