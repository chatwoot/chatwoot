require 'rails_helper'

RSpec.describe Labelable::Persistence do
  %i[conversation contact].each do |factory|
    context "with a #{factory}" do
      let(:record) { create(factory) }
      let(:other_instance) { record.class.find(record.id) }

      it 'preserves labels added by another instance after the list was read' do
        expect(record.label_list).to be_empty
        other_instance.update_labels(['runner'])

        record.update!(custom_attributes: { 'note' => 'Unrelated edit' })

        expect(record.saved_change_to_label_list?).to be(false)
        expect(record.reload.labels.pluck(:name)).to eq(['runner'])
      end

      it 'does not restore labels removed by another instance' do
        record.update_labels(['runner'])
        record.label_list
        other_instance.update_labels([])

        record.update!(custom_attributes: { 'note' => 'Unrelated edit' })

        expect(record.reload.labels).to be_empty
      end

      it 'preserves concurrent additions after a previous label save on the same instance' do
        record.update_labels(['runner'])
        other_instance.add_labels(['lead'])

        record.update!(custom_attributes: { 'note' => 'Unrelated edit' })

        expect(record.reload.labels.pluck(:name)).to contain_exactly('runner', 'lead')
      end

      it 'persists explicit label additions and removals' do
        record.update_labels(['runner'])
        expect(record.saved_change_to_label_list?).to be(true)
        expect(record.reload.labels.pluck(:name)).to eq(['runner'])

        record.update_labels([])
        expect(record.saved_change_to_label_list?).to be(true)
        expect(record.reload.labels).to be_empty
      end

      it 'persists in-place additions and removals across successive saves' do
        record.label_list.add('runner')
        record.save!
        expect(other_instance.labels.pluck(:name)).to eq(['runner'])

        record.label_list.remove('runner')
        record.label_list.add('lead')
        record.save!
        expect(other_instance.reload.labels.pluck(:name)).to eq(['lead'])
      end

      it 'uses the reloaded list as the baseline for subsequent edits' do
        record.update_labels(['runner'])
        other_instance.update_labels(['lead'])

        record.reload
        record.label_list.remove('lead')
        record.label_list.add('runner')
        record.save!

        expect(other_instance.reload.labels.pluck(:name)).to eq(['runner'])
      end

      it 'retains pending label edits after validation fails' do
        record.label_list.add('runner')
        record.account = nil
        expect(record.save).to be(false)

        record.account = other_instance.account
        record.save!

        expect(other_instance.reload.labels.pluck(:name)).to eq(['runner'])
      end

      it 'persists a label edit retried after its transaction rolled back' do
        record.class.transaction(requires_new: true) do
          record.update_labels(['runner'])
          raise ActiveRecord::Rollback
        end
        expect(other_instance.labels).to be_empty

        record.save!

        expect(other_instance.reload.labels.pluck(:name)).to eq(['runner'])
      end

      it 'persists a list set through set_tag_list_on without a prior read' do
        other_instance.set_tag_list_on(:labels, ['runner'])
        other_instance.save!

        expect(record.reload.labels.pluck(:name)).to eq(['runner'])
      end
    end
  end

  context 'with a conversation label cache' do
    let(:conversation) { create(:conversation) }

    [nil, ''].each do |cached_labels|
      it "preserves a newer cache when the original cache was #{cached_labels.inspect}" do
        conversation.update!(cached_label_list: cached_labels)
        stale_instance = Conversation.find(conversation.id)
        expect(stale_instance.label_list).to be_empty
        conversation.update_labels(['runner'])

        stale_instance.update!(first_reply_created_at: Time.current, waiting_since: nil)

        expect(conversation.reload.cached_label_list).to eq('runner')
        expect(conversation.labels.pluck(:name)).to eq(['runner'])
      end
    end

    it 'updates the cache when labels are intentionally changed' do
      conversation.label_list.add('runner')
      conversation.save!
      expect(conversation.reload.cached_label_list).to eq('runner')

      conversation.update_labels([])
      expect(conversation.reload.cached_label_list).to eq('')
    end
  end
end
