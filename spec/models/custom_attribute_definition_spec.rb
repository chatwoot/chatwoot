# frozen_string_literal: true

# == Schema Information
#
# Table name: custom_attribute_definitions
#
#  id                     :bigint           not null, primary key
#  attribute_description  :text
#  attribute_display_name :string
#  attribute_display_type :integer          default("text")
#  attribute_key          :string
#  attribute_model        :integer          default("conversation_attribute")
#  attribute_values       :jsonb
#  default_value          :integer
#  regex_cue              :string
#  regex_pattern          :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint
#
# Indexes
#
#  attribute_key_model_index                         (attribute_key,attribute_model,account_id) UNIQUE
#  index_custom_attribute_definitions_on_account_id  (account_id)
#
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
