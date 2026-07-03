require 'rails_helper'

RSpec.describe Autonomia::Agents::BuildThread do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }
  let(:thread) { described_class.create!(account: account) }

  describe 'tenancy validation' do
    it 'accepts a thread without an agent (draft interview)' do
      # Arrange / Act
      thread = described_class.new(account: account)

      # Assert
      expect(thread).to be_valid
    end

    it 'accepts a thread whose agent belongs to the same account' do
      # Arrange
      agent = Autonomia::Agents::Agent.create!(account: account, name: 'Agente', agent_type: 'custom')

      # Act
      thread = described_class.new(account: account, agent: agent)

      # Assert
      expect(thread).to be_valid
    end

    it 'rejects a thread whose agent belongs to another account' do
      # Arrange
      foreign_agent = Autonomia::Agents::Agent.create!(account: other_account, name: 'Alheio', agent_type: 'custom')

      # Act
      thread = described_class.new(account: account, agent: foreign_agent)

      # Assert
      expect(thread).not_to be_valid
      expect(thread.errors[:agent]).to include('must belong to the same account')
    end
  end

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

  describe '#begin_build! atomic claim (T6)' do
    it 'lets only one of two competing claims win while the build is fresh' do
      # Arrange + Act
      first_token = thread.begin_build!
      second_token = thread.begin_build!

      # Assert — the loser gets nil and the winner token stays active
      expect(first_token).to be_present
      expect(second_token).to be_nil
      expect(thread.reload.build_token).to eq(first_token)
    end

    it 'reclaims the slot once the previous processing build went stale' do
      # Arrange
      stale_token = thread.begin_build!

      # Act
      new_token = nil
      travel_to(10.minutes.from_now) { new_token = thread.begin_build! }

      # Assert
      expect(new_token).to be_present
      expect(new_token).not_to eq(stale_token)
      expect(thread.reload.build_token).to eq(new_token)
    end

    it 'claims normally from a failed thread' do
      # Arrange
      token = thread.begin_build!
      thread.mark_failed!(token, 'boom')

      # Act + Assert
      expect(thread.begin_build!).to be_present
      expect(thread.reload).to be_processing
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
