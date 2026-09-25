require 'rails_helper'

RSpec.describe Labelable do
  %i[conversation contact].each do |factory|
    context "with a #{factory}" do
      let(:record) { create(factory) }
      let(:other_instance) { record.class.find(record.id) }

      it 'preserves labels added elsewhere after the list was read' do
        expect(record.label_list).to be_empty
        other_instance.update_labels(['runner'])

        record.update!(custom_attributes: { 'note' => 'Unrelated edit' })

        expect(record.saved_change_to_label_list?).to be(false)
        expect(record.reload.labels.pluck(:name)).to eq(['runner'])
      end

      it 'does not restore labels removed elsewhere after the list was read' do
        record.update_labels(['runner'])
        other_instance.update_labels([])

        record.update!(custom_attributes: { 'note' => 'Unrelated edit' })

        expect(record.reload.labels.pluck(:name)).to be_empty
      end

      it 'preserves labels added elsewhere after this instance saved its own labels' do
        record.update_labels(['runner'])
        other_instance.add_labels(['lead'])

        record.update!(custom_attributes: { 'note' => 'Unrelated edit' })

        expect(record.reload.labels.pluck(:name)).to contain_exactly('runner', 'lead')
      end

      it 'does not write labels when the assigned list matches the loaded list' do
        record.update_labels(['runner'])
        other_instance.add_labels(['lead'])

        record.update!(label_list: ['runner'])

        expect(record.saved_change_to_label_list?).to be(false)
        expect(record.reload.labels.pluck(:name)).to contain_exactly('runner', 'lead')
      end

      it 'persists labels assigned at creation' do
        created = create(factory, label_list: %w[runner lead])

        expect(created.reload.labels.pluck(:name)).to contain_exactly('runner', 'lead')
      end

      it 'persists assigned additions and removals' do
        record.update_labels(%w[runner lead])
        expect(record.saved_change_to_label_list?).to be(true)
        expect(other_instance.reload.labels.pluck(:name)).to contain_exactly('runner', 'lead')

        record.update_labels(['lead'])
        expect(record.saved_change_to_label_list?).to be(true)
        expect(other_instance.reload.labels.pluck(:name)).to eq(['lead'])

        record.update_labels([])
        expect(record.reload.labels.pluck(:name)).to be_empty
      end

      it 'merges added labels with the latest saved labels' do
        record.label_list
        other_instance.update_labels(['lead'])

        record.add_labels(['runner'])

        expect(record.reload.labels.pluck(:name)).to contain_exactly('lead', 'runner')
      end

      it 'does not persist in-place edits that are not assigned' do
        record.label_list.add('runner')
        record.save!

        expect(other_instance.reload.labels.pluck(:name)).to be_empty
      end

      it 'persists an assignment retried after validation fails' do
        record.label_list = ['runner']
        record.account = nil
        expect(record.save).to be(false)

        record.account = other_instance.account
        record.save!

        expect(other_instance.reload.labels.pluck(:name)).to eq(['runner'])
      end

      it 'discards an unsaved assignment on reload' do
        record.label_list = ['runner']
        record.reload

        record.update!(custom_attributes: { 'note' => 'Unrelated edit' })

        expect(other_instance.reload.labels.pluck(:name)).to be_empty
      end
    end
  end

  context 'with a conversation label cache' do
    let(:conversation) { create(:conversation) }

    [nil, ''].each do |cached_labels|
      it "preserves a newer cache when the loaded cache was #{cached_labels.inspect}" do
        conversation.update!(cached_label_list: cached_labels)
        stale_instance = Conversation.find(conversation.id)
        expect(stale_instance.label_list).to be_empty
        conversation.update_labels(['runner'])

        stale_instance.update!(first_reply_created_at: Time.current, waiting_since: nil)

        expect(conversation.reload.cached_label_list).to eq('runner')
        expect(conversation.labels.pluck(:name)).to eq(['runner'])
      end
    end

    it 'updates the cache when labels are assigned' do
      conversation.update_labels(%w[runner lead])
      expect(conversation.reload.cached_label_list).to eq('runner, lead')

      conversation.update_labels([])
      expect(conversation.reload.cached_label_list).to eq('')
    end
  end

  context 'when an agent reply follows a conversation-created automation' do
    let(:conversation) { create(:conversation) }
    let(:agent) { create(:user, account: conversation.account) }

    it 'keeps the automation label after the first reply is recorded' do
      conversation.push_event_data
      conversation.label_list
      Conversation.find(conversation.id).add_labels(['runner'])

      create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox,
                       message_type: :outgoing, sender: agent)

      expect(conversation.first_reply_created_at).to be_present
      expect(conversation.reload.labels.pluck(:name)).to eq(['runner'])
      expect(conversation.cached_label_list).to eq('runner')
    end
  end
end
