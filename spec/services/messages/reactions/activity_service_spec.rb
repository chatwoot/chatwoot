# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Reactions::ActivityService do
  let(:reaction) { create(:message_reaction, emoji: '👍', reaction_type: 'emoji', status: :active) }
  let(:conversation) { reaction.conversation }
  let(:dispatcher) { Rails.configuration.dispatcher }

  before do
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_columns(last_activity_at: 2.days.ago)
    # rubocop:enable Rails/SkipsModelValidations
    allow(dispatcher).to receive(:dispatch).and_call_original
  end

  def perform(overrides = {})
    described_class.new(reaction: reaction,
                        was_new_record: false,
                        previous_status: 'active',
                        previous_emoji: '👍',
                        previous_reaction_type: 'emoji', **overrides).perform
  end

  context 'when the reaction is a brand new active row' do
    it 'dispatches MESSAGE_REACTION_CREATED and bumps conversation activity' do
      perform(was_new_record: true, previous_status: 'active', previous_emoji: nil, previous_reaction_type: nil)

      expect(dispatcher).to have_received(:dispatch).with(
        Events::Types::MESSAGE_REACTION_CREATED,
        kind_of(Time),
        hash_including(message_reaction: reaction, message: reaction.message, conversation: conversation,
                       account: reaction.account, inbox: reaction.inbox, sender: reaction.sender)
      )
      expect(conversation.reload.last_activity_at).to be_within(5.seconds).of(Time.current)
    end
  end

  context 'when the reaction is brand new but immediately removed (unreact with no prior state)' do
    it 'dispatches MESSAGE_REACTION_REMOVED rather than CREATED' do
      reaction.update!(status: :removed)

      perform(was_new_record: true, previous_status: 'active', previous_emoji: nil, previous_reaction_type: nil)

      expect(dispatcher).to have_received(:dispatch).with(Events::Types::MESSAGE_REACTION_REMOVED, kind_of(Time), anything)
    end
  end

  context 'when an existing active reaction changes emoji' do
    it 'dispatches MESSAGE_REACTION_UPDATED and bumps activity' do
      perform(previous_emoji: '😀')

      expect(dispatcher).to have_received(:dispatch).with(Events::Types::MESSAGE_REACTION_UPDATED, kind_of(Time), anything)
      expect(conversation.reload.last_activity_at).to be_within(5.seconds).of(Time.current)
    end
  end

  context 'when an existing active reaction transitions to removed' do
    it 'dispatches MESSAGE_REACTION_REMOVED and bumps activity' do
      reaction.update!(status: :removed)

      perform(previous_status: 'active')

      expect(dispatcher).to have_received(:dispatch).with(Events::Types::MESSAGE_REACTION_REMOVED, kind_of(Time), anything)
      expect(conversation.reload.last_activity_at).to be_within(5.seconds).of(Time.current)
    end
  end

  context 'when nothing actually changed (true duplicate)' do
    it 'does not dispatch an event and does not bump activity' do
      perform

      expect(dispatcher).not_to have_received(:dispatch)
      expect(conversation.reload.last_activity_at).to be_within(1.second).of(2.days.ago)
    end
  end

  context 'when an already-removed reaction is unreacted again' do
    it 'does not dispatch an event and does not bump activity' do
      reaction.update!(status: :removed)

      perform(previous_status: 'removed')

      expect(dispatcher).not_to have_received(:dispatch)
      expect(conversation.reload.last_activity_at).to be_within(1.second).of(2.days.ago)
    end
  end

  context 'when a removed reaction is reactivated (react after unreact)' do
    it 'dispatches MESSAGE_REACTION_UPDATED rather than CREATED' do
      perform(previous_status: 'removed')

      expect(dispatcher).to have_received(:dispatch).with(Events::Types::MESSAGE_REACTION_UPDATED, kind_of(Time), anything)
      expect(dispatcher).not_to have_received(:dispatch).with(Events::Types::MESSAGE_REACTION_CREATED, anything, anything)
      expect(conversation.reload.last_activity_at).to be_within(5.seconds).of(Time.current)
    end
  end
end
