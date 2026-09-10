# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomAttributeDefinition do
  let(:account) { create(:account) }

  describe 'validations' do
    describe 'attribute_key format' do
      it 'allows alphanumeric keys with underscores' do
        cad = build(:custom_attribute_definition, account: account, attribute_key: 'order_date_1')
        expect(cad).to be_valid
      end

      it 'allows hyphens and dots' do
        cad = build(:custom_attribute_definition, account: account, attribute_key: 'order-date.v2')
        expect(cad).to be_valid
      end

      it 'allows Unicode letters' do
        cad = build(:custom_attribute_definition, account: account, attribute_key: '客户类型')
        expect(cad).to be_valid
      end

      it 'rejects keys with single quotes' do
        cad = build(:custom_attribute_definition, account: account, attribute_key: "x'||(SELECT 1)||'")
        expect(cad).not_to be_valid
        expect(cad.errors[:attribute_key]).to be_present
      end

      it 'rejects keys with spaces' do
        cad = build(:custom_attribute_definition, account: account, attribute_key: 'order date')
        expect(cad).not_to be_valid
      end

      it 'rejects keys with semicolons' do
        cad = build(:custom_attribute_definition, account: account, attribute_key: 'key; DROP TABLE users--')
        expect(cad).not_to be_valid
      end

      it 'rejects keys with parentheses' do
        cad = build(:custom_attribute_definition, account: account, attribute_key: 'key()')
        expect(cad).not_to be_valid
      end

      it 'allows company custom attributes' do
        cad = build(:custom_attribute_definition, account: account, attribute_model: 'company_attribute')
        expect(cad).to be_valid
      end

      it 'rejects company custom attributes that conflict with standard company fields' do
        cad = build(:custom_attribute_definition, account: account, attribute_model: 'company_attribute', attribute_key: 'domain')
        expect(cad).not_to be_valid
        expect(cad.errors[:attribute_key]).to be_present
      end
    end
  end

  describe 'callbacks' do
    describe '#strip_attribute_key' do
      it 'strips leading and trailing whitespace from attribute_key' do
        cad = create(:custom_attribute_definition, account: account, attribute_key: '  order_date  ')
        expect(cad.attribute_key).to eq('order_date')
      end

      it 'strips leading and trailing whitespace from attribute_display_name' do
        cad = create(:custom_attribute_definition, account: account, attribute_display_name: '  Order Date  ')
        expect(cad.attribute_display_name).to eq('Order Date')
      end
    end

    describe 'filtered unread count invalidation' do
      let(:invalidator) { instance_double(Conversations::UnreadCounts::FilteredCountInvalidator, custom_attribute_definition_changed!: true) }

      before do
        allow(Conversations::UnreadCounts::FilteredCountInvalidator).to receive(:new).with(account).and_return(invalidator)
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
      end

      it 'invalidates conversation filters when a conversation custom attribute definition changes' do
        cad = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute')

        cad.update!(attribute_display_name: 'Updated Order Date')

        expect(invalidator).to have_received(:custom_attribute_definition_changed!).with(cad)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
          'account.cache_invalidated',
          kind_of(Time),
          account: account,
          cache_keys: account.cache_keys
        )
      end

      it 'invalidates conversation filters when a conversation custom attribute definition is deleted' do
        cad = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute')

        cad.destroy!

        expect(invalidator).to have_received(:custom_attribute_definition_changed!).with(cad)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
          'account.cache_invalidated',
          kind_of(Time),
          account: account,
          cache_keys: account.cache_keys
        )
      end

      it 'ignores contact custom attribute definition changes' do
        cad = create(:custom_attribute_definition, account: account, attribute_model: 'contact_attribute')

        cad.update!(attribute_display_name: 'Updated Contact Field')

        expect(invalidator).not_to have_received(:custom_attribute_definition_changed!)
        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
      end
    end

    describe '#set_position' do
      it 'assigns an incremental position scoped to account and attribute_model' do
        first = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute')
        second = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute')

        expect(first.position).to eq(10)
        expect(second.position).to eq(20)
      end

      it 'tracks positions independently per attribute_model' do
        conversation_cad = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute')
        contact_cad = create(:custom_attribute_definition, account: account, attribute_model: 'contact_attribute')

        expect(conversation_cad.position).to eq(10)
        expect(contact_cad.position).to eq(10)
      end

      context 'when attribute_model changes on update' do
        it 'reassigns position to the end of the destination attribute_model scope' do
          existing_contact_cad = create(:custom_attribute_definition, account: account, attribute_model: 'contact_attribute')
          cad = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute')

          cad.update!(attribute_model: 'contact_attribute')

          expect(cad.reload.position).to eq(existing_contact_cad.position + 10)
        end

        it 'appends to an empty destination scope starting at 10' do
          cad = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute')

          cad.update!(attribute_model: 'company_attribute')

          expect(cad.reload.position).to eq(10)
        end

        it 'does not collide with an existing record already at the same position in the destination scope' do
          existing_company_cad = create(:custom_attribute_definition, account: account, attribute_model: 'company_attribute')
          cad = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute')

          cad.update!(attribute_model: 'company_attribute')

          expect(cad.reload.position).not_to eq(existing_company_cad.reload.position)
        end

        it 'does not change position when attribute_model is not part of the update' do
          cad = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute')
          original_position = cad.position

          cad.update!(attribute_display_name: 'Renamed')

          expect(cad.reload.position).to eq(original_position)
        end
      end
    end
  end

  describe '.update_positions' do
    it 'updates positions for the given account-scoped ids' do
      first = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute')
      second = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute')

      described_class.update_positions(account: account, positions_hash: { first.id => 20, second.id => 10 })

      expect(first.reload.position).to eq(20)
      expect(second.reload.position).to eq(10)
    end

    it 'does nothing when positions_hash is blank' do
      cad = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute')

      expect { described_class.update_positions(account: account, positions_hash: {}) }
        .not_to(change { cad.reload.position })
    end
  end
end
