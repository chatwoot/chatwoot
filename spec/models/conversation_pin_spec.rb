require 'rails_helper'

RSpec.describe ConversationPin do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:user) { create(:user, account: account, role: :agent) }

    before { create(:inbox_member, user: user, inbox: inbox) }

    it 'ensures account is present' do
      conversation = create(:conversation, account: account, inbox: inbox)
      conversation_pin = build(:conversation_pin, conversation: conversation, user: user, account_id: nil)
      conversation_pin.valid?
      expect(conversation_pin.account_id).to eq(conversation.account_id)
    end

    it 'does not allow the same user to pin a conversation twice' do
      conversation = create(:conversation, account: account, inbox: inbox)
      create(:conversation_pin, conversation: conversation, user: user, account: account)
      duplicate = build(:conversation_pin, conversation: conversation, user: user, account: account)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors.messages[:user_id]).to eq(['has already been taken'])
    end

    it 'allows two users to pin the same conversation' do
      conversation = create(:conversation, account: account, inbox: inbox)
      other_user = create(:user, account: account, role: :agent)
      create(:inbox_member, user: other_user, inbox: inbox)
      create(:conversation_pin, conversation: conversation, user: user, account: account)

      expect(build(:conversation_pin, conversation: conversation, user: other_user, account: account)).to be_valid
    end
  end

  describe 'resolved conversations' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:user) { create(:user, account: account, role: :agent) }

    before { create(:inbox_member, user: user, inbox: inbox) }

    it 'rejects a pin on a resolved conversation' do
      conversation = create(:conversation, account: account, inbox: inbox, status: :resolved)
      pin = build(:conversation_pin, conversation: conversation, user: user, account: account)

      expect(pin).not_to be_valid
      expect(pin.errors.full_messages).to eq(['A resolved conversation cannot be pinned.'])
    end

    it 'allows a pin on a pending conversation' do
      conversation = create(:conversation, account: account, inbox: inbox, status: :pending)

      expect(build(:conversation_pin, conversation: conversation, user: user, account: account)).to be_valid
    end

    it 'does not free the slot of an existing pin when the conversation is resolved later' do
      conversation = create(:conversation, account: account, inbox: inbox)
      pin = create(:conversation_pin, conversation: conversation, user: user, account: account)

      expect(pin.reload).to be_persisted
    end
  end

  describe 'pin limit' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:user) { create(:user, account: account, role: :agent) }

    before do
      create(:inbox_member, user: user, inbox: inbox)
      described_class::MAX_PER_USER.times do
        conversation = create(:conversation, account: account, inbox: inbox)
        create(:conversation_pin, conversation: conversation, user: user, account: account)
      end
    end

    it 'rejects a pin beyond the limit' do
      extra = build(:conversation_pin, conversation: create(:conversation, account: account, inbox: inbox), user: user, account: account)

      expect(extra).not_to be_valid
      expect(extra.errors.full_messages).to eq(["You can pin up to #{described_class::MAX_PER_USER} conversations."])
    end

    it 'counts the limit per account' do
      other_account = create(:account)
      other_inbox = create(:inbox, account: other_account)
      create(:account_user, account: other_account, user: user, role: :agent)
      create(:inbox_member, user: user, inbox: other_inbox)
      conversation = create(:conversation, account: other_account, inbox: other_inbox)

      expect(build(:conversation_pin, conversation: conversation, user: user, account: other_account)).to be_valid
    end

    it 'counts the limit per user' do
      other_user = create(:user, account: account, role: :agent)
      create(:inbox_member, user: other_user, inbox: inbox)
      conversation = create(:conversation, account: account, inbox: inbox)

      expect(build(:conversation_pin, conversation: conversation, user: other_user, account: account)).to be_valid
    end

    it 'frees a slot when a pin is removed' do
      described_class.where(user: user).first.destroy!
      conversation = create(:conversation, account: account, inbox: inbox)

      expect(build(:conversation_pin, conversation: conversation, user: user, account: account)).to be_valid
    end
  end

  describe 'visibility' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:user) { create(:user, account: account, role: :agent) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let!(:inbox_member) { create(:inbox_member, user: user, inbox: inbox) }

    it 'lists a pin the agent can still see' do
      pin = create(:conversation_pin, conversation: conversation, user: user, account: account)

      expect(described_class.visible_to(user, account)).to eq([pin])
    end

    it 'hides a pin once the agent leaves the inbox' do
      create(:conversation_pin, conversation: conversation, user: user, account: account)
      inbox_member.destroy!

      expect(described_class.visible_to(user, account)).to be_empty
    end

    it 'gives the pin back when access returns' do
      pin = create(:conversation_pin, conversation: conversation, user: user, account: account)
      inbox_member.destroy!
      create(:inbox_member, user: user, inbox: inbox)

      expect(described_class.visible_to(user, account)).to eq([pin])
    end

    it 'hides a pin whose conversation is already gone' do
      create(:conversation_pin, conversation: conversation, user: user, account: account)
      Conversation.where(id: conversation.id).delete_all

      expect(described_class.visible_to(user, account)).to be_empty
    end

    it 'hides the pins of other agents' do
      other_user = create(:user, account: account, role: :agent)
      create(:inbox_member, user: other_user, inbox: inbox)
      create(:conversation_pin, conversation: conversation, user: other_user, account: account)

      expect(described_class.visible_to(user, account)).to be_empty
    end

    it 'rejects a pin on a conversation the list would never show' do
      other_inbox = create(:inbox, account: account)
      unreachable = create(:conversation, account: account, inbox: other_inbox)
      pin = build(:conversation_pin, conversation: unreachable, user: user, account: account)

      expect(pin).not_to be_valid
      expect(pin.errors.full_messages).to eq(['This conversation is not in your list, so it cannot be pinned.'])
    end

    it 'counts hidden pins against the limit until they are pruned' do
      described_class::MAX_PER_USER.times do
        pinned = create(:conversation, account: account, inbox: inbox)
        create(:conversation_pin, conversation: pinned, user: user, account: account)
      end
      inbox_member.destroy!
      other_inbox = create(:inbox, account: account)
      create(:inbox_member, user: user, inbox: other_inbox)
      reachable = create(:conversation, account: account, inbox: other_inbox)

      expect(build(:conversation_pin, conversation: reachable, user: user, account: account)).not_to be_valid
    end

    it 'frees those slots once they are pruned' do
      described_class::MAX_PER_USER.times do
        pinned = create(:conversation, account: account, inbox: inbox)
        create(:conversation_pin, conversation: pinned, user: user, account: account)
      end
      inbox_member.destroy!
      other_inbox = create(:inbox, account: account)
      create(:inbox_member, user: user, inbox: other_inbox)
      reachable = create(:conversation, account: account, inbox: other_inbox)

      described_class.prune_hidden(user, account)

      expect(described_class.where(user: user).count).to eq(0)
      expect(build(:conversation_pin, conversation: reachable, user: user, account: account)).to be_valid
    end

    it 'keeps the pins the agent can still see when pruning' do
      pin = create(:conversation_pin, conversation: conversation, user: user, account: account)

      expect { described_class.prune_hidden(user, account) }.not_to change(described_class, :count)
      expect(pin.reload).to be_persisted
    end
  end

  describe 'events' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:user) { create(:user, account: account, role: :agent) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    before { create(:inbox_member, user: user, inbox: inbox) }

    it 'dispatches a pinned event with serialized data' do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      pin = create(:conversation_pin, conversation: conversation, user: user, account: account)

      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
        described_class::CONVERSATION_PINNED,
        kind_of(Time),
        conversation_pin: {
          account_id: account.id,
          user_id: user.id,
          conversation_id: conversation.display_id,
          pinned_at: pin.created_at.to_f
        }
      )
    end

    it 'dispatches an unpinned event with serialized data' do
      pin = create(:conversation_pin, conversation: conversation, user: user, account: account)
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      pin.destroy!

      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
        described_class::CONVERSATION_UNPINNED,
        kind_of(Time),
        conversation_pin: {
          account_id: account.id,
          user_id: user.id,
          conversation_id: conversation.display_id,
          pinned_at: pin.created_at.to_f
        }
      )
    end

    it 'does not dispatch when the conversation is already gone' do
      pin = create(:conversation_pin, conversation: conversation, user: user, account: account)
      allow(pin).to receive_messages(conversation: nil)
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      expect { pin.destroy! }.not_to raise_error
      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
    end
  end
end
