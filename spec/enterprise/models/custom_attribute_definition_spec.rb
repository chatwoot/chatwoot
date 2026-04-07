# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomAttributeDefinition do
  describe 'callbacks' do
    describe '#cleanup_conversation_required_attributes' do
      let(:account) { create(:account) }
      let(:attribute_key) { 'test_attribute' }
      let!(:custom_attribute) do
        create(:custom_attribute_definition,
               account: account,
               attribute_key: attribute_key,
               attribute_model: 'conversation_attribute')
      end

      context 'when conversation attribute is in required attributes list' do
        before do
          account.update!(conversation_required_attributes: [attribute_key, 'other_attribute'])
        end

        it 'removes the attribute from conversation_required_attributes when destroyed' do
          expect { custom_attribute.destroy! }
            .to change { account.reload.conversation_required_attributes }
            .from([attribute_key, 'other_attribute'])
            .to(['other_attribute'])
        end
      end

      context 'when attribute is contact_attribute' do
        let!(:contact_attribute) do
          create(:custom_attribute_definition,
                 account: account,
                 attribute_key: attribute_key,
                 attribute_model: 'contact_attribute')
        end

        before do
          account.update!(conversation_required_attributes: [attribute_key])
        end

        it 'does not modify conversation_required_attributes when destroyed' do
          expect { contact_attribute.destroy! }
            .not_to(change { account.reload.conversation_required_attributes })
        end
      end
    end
  end
end
