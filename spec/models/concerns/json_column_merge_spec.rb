require 'rails_helper'

RSpec.describe JsonColumnMerge do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, additional_attributes: { 'city' => 'Curitiba' }) }

  describe '#merge_json_column!' do
    it 'merges against the row rather than against this object' do
      Contact.find(contact.id).update!(additional_attributes: { 'city' => 'Curitiba', 'company_name' => 'fazer.ai' })

      contact.merge_json_column!(:additional_attributes, merge: { 'country' => 'Brazil' })

      expect(contact.reload.additional_attributes)
        .to eq('city' => 'Curitiba', 'company_name' => 'fazer.ai', 'country' => 'Brazil')
    end

    # A mechanism test, and named as one. Re-reading is what fixes the defect this exists for, a
    # copy that went stale across a network call, and the example above measures that outcome.
    # The lock answers the other half, two processes re-reading and writing at the same instant,
    # and a single-threaded suite cannot stage that. Without this the lock could be deleted with
    # every example still green.
    it 'reads the row for update' do
      statements = []
      subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        statements << payload[:sql]
      end

      contact.merge_json_column!(:additional_attributes, merge: { 'country' => 'Brazil' })

      ActiveSupport::Notifications.unsubscribe(subscription)
      expect(statements).to include(a_string_matching(/SELECT .* FROM "contacts" .* FOR UPDATE/m))
    end

    it 'leaves the receiver alone, because the lock is taken on a separate row object' do
      contact.merge_json_column!(:additional_attributes, merge: { 'country' => 'Brazil' })

      expect(contact.additional_attributes).to eq('city' => 'Curitiba')
    end

    # A Conversation carries a dirty `display_id` from creation on purpose, so anything built on
    # `with_lock` would raise here instead of writing.
    it 'writes even when the record has unsaved changes' do
      conversation = create(:conversation, account: account)

      expect(conversation.changed).to include('display_id')
      expect { conversation.merge_json_column!(:additional_attributes, merge: { 'conversation_language' => 'pt' }) }
        .not_to raise_error
      expect(conversation.reload.additional_attributes).to include('conversation_language' => 'pt')
    end

    it 'takes a symbol key as the same key' do
      contact.merge_json_column!(:additional_attributes, merge: { city: 'Sao Paulo' })

      expect(contact.reload.additional_attributes).to eq('city' => 'Sao Paulo')
    end

    # Assigning the column normalises the spelling on its own, so the stored value is right
    # either way. What stringifying buys is this: the check for a write that changes nothing
    # runs before the assignment, against String keys, so without it a symbol-keyed merge would
    # never look equal and would write, and fire its callbacks, on every call.
    it 'does not touch the row when a symbol-keyed merge changes nothing' do
      before_write = contact.reload.updated_at

      expect(contact.merge_json_column!(:additional_attributes, merge: { city: 'Curitiba' })).to be(false)
      expect(contact.reload.updated_at).to eq(before_write)
    end

    it 'carries the other columns of the same write' do
      contact.merge_json_column!(:additional_attributes, attributes: { name: 'Equipe' }, merge: { 'owner' => '1@lid' })

      expect(contact.reload).to have_attributes(name: 'Equipe')
      expect(contact.additional_attributes).to include('owner' => '1@lid')
    end

    # The write has to keep being a write: `before_save :sync_contact_attributes` is what copies
    # `city` into the `location` column, and `update_columns` would skip it in silence.
    it 'still runs the callbacks a write runs' do
      contact.merge_json_column!(:additional_attributes, merge: { 'city' => 'Sao Paulo' })

      expect(contact.reload.location).to eq('Sao Paulo')
    end

    it 'does not touch the row when the merge changes nothing' do
      before_write = contact.reload.updated_at

      expect(contact.merge_json_column!(:additional_attributes, merge: { 'city' => 'Curitiba' })).to be(false)
      expect(contact.reload.updated_at).to eq(before_write)
    end

    # Every caller is enrichment after a network round trip. Before this existed the write simply
    # matched zero rows and the job ended clean; raising would turn a deleted contact into a job
    # that retries until it gives up.
    it 'answers false when the row disappeared during the call' do
      id = contact.id
      Contact.find(id).destroy!

      expect(contact.merge_json_column!(:additional_attributes, merge: { 'city' => 'Sao Paulo' })).to be(false)
    end

    describe 'writing inside a nested namespace' do
      it 'keeps the siblings already stored there' do
        contact.update!(additional_attributes: { 'external' => { 'hubspot_id' => 'hs_1' } })

        contact.merge_json_column!(:additional_attributes, under: 'external', merge: { 'leadsquared_id' => 'ls_1' })

        expect(contact.reload.additional_attributes['external'])
          .to eq('hubspot_id' => 'hs_1', 'leadsquared_id' => 'ls_1')
      end

      it 'removes one key and leaves the rest of the namespace standing' do
        contact.update!(additional_attributes: { 'external' => { 'hubspot_id' => 'hs_1', 'leadsquared_id' => 'ls_1' } })

        contact.merge_json_column!(:additional_attributes, under: 'external', remove: ['leadsquared_id'])

        expect(contact.reload.additional_attributes['external']).to eq('hubspot_id' => 'hs_1')
      end

      it 'does not seed an empty namespace for a removal that had nowhere to happen' do
        expect(contact.merge_json_column!(:additional_attributes, under: 'external', remove: ['leadsquared_id'])).to be(false)
        expect(contact.reload.additional_attributes).to eq('city' => 'Curitiba')
      end

      # Whatever is stored under the key, if it is not a hash it is not a namespace, and writing
      # inside it means replacing it.
      it 'replaces a stored value that is not a hash' do
        contact.update!(additional_attributes: { 'external' => 'ls_1' })

        contact.merge_json_column!(:additional_attributes, under: 'external', merge: { 'leadsquared_id' => 'ls_1' })

        expect(contact.reload.additional_attributes['external']).to eq('leadsquared_id' => 'ls_1')
      end
    end
  end

  describe '#swap_json_column!' do
    let(:contact) { create(:contact, additional_attributes: { 'token' => 'T1', 'city' => 'Curitiba' }) }

    it 'writes when the row still holds what the caller based its call on' do
      expect(contact.swap_json_column!(:additional_attributes, expect: { 'token' => 'T1' }, merge: { 'token' => 'T2' }))
        .to be(:written)
      expect(contact.reload.additional_attributes).to eq('token' => 'T2', 'city' => 'Curitiba')
    end

    # The whole point: not an error, not a raise, and above all not a write. The caller has to be
    # able to tell this apart from "there was nothing to write", which is why the answer is a symbol
    # and not a boolean.
    it 'writes nothing when another writer got there first' do
      contact.update!(additional_attributes: { 'token' => 'T_OTHER', 'city' => 'Curitiba' })

      expect(contact.swap_json_column!(:additional_attributes, expect: { 'token' => 'T1' }, merge: { 'token' => 'T2' }))
        .to be(:stale)
      expect(contact.reload.additional_attributes['token']).to eq('T_OTHER')
    end

    it 'compares the stored value whether the caller asked with a symbol or a string' do
      expect(contact.swap_json_column!(:additional_attributes, expect: { token: 'T1' }, merge: { 'token' => 'T2' }))
        .to be(:written)
    end

    it 'answers that it did not write when the write would change nothing' do
      expect(contact.swap_json_column!(:additional_attributes, expect: { 'token' => 'T1' }, merge: { 'token' => 'T1' }))
        .to be(:unchanged)
    end

    # A key the row does not have is not the value the caller expected, so an `expect` on it is a
    # precondition that fails rather than one that is vacuously true.
    it 'does not write when the key it expected is not there at all' do
      contact.update!(additional_attributes: { 'city' => 'Curitiba' })

      expect(contact.swap_json_column!(:additional_attributes, expect: { 'token' => 'T1' }, merge: { 'token' => 'T2' }))
        .to be(:stale)
    end

    # The compare and the write have to come from the same locked read, or this is a check followed
    # by a hope: another writer lands in between and the loser overwrites it anyway, which is the
    # whole defect. Nothing a single connection can do shows the difference, and a mutation that
    # moves the read out of the lock survives every example above, so what is asserted here is the
    # property itself: inside the swap, no read of this row happens without the lock.
    it 'compares a value it read under the lock' do
      contact.id

      reads = []
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        reads << payload[:sql] if payload[:sql].match?(/SELECT .+ FROM "contacts"/i)
      end

      begin
        contact.swap_json_column!(:additional_attributes, expect: { 'token' => 'T1' }, merge: { 'token' => 'T2' })
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      expect(reads).to be_present
      expect(reads.grep_v(/FOR UPDATE/i)).to be_empty
    end

    it 'writes with no precondition when nothing is expected' do
      expect(contact.swap_json_column!(:additional_attributes, expect: {}, merge: { 'token' => 'T2' })).to be(:written)
    end

    it 'writes the other columns that belong to the same write' do
      expect(contact.swap_json_column!(:additional_attributes, expect: { 'token' => 'T1' },
                                                               merge: { 'token' => 'T2' }, attributes: { name: 'Equipe' }))
        .to be(:written)
      expect(contact.reload.name).to eq('Equipe')
    end

    # Same reason as the merge: every caller is enrichment after a network round trip, so a row that
    # went away during the call ends the work instead of raising into a retry loop.
    it 'answers that the row is gone instead of raising' do
      id = contact.id
      contact.destroy!

      expect(Contact.new(id: id).swap_json_column!(:additional_attributes, expect: {}, merge: { 'token' => 'T2' }))
        .to be(:gone)
    end
  end
end
