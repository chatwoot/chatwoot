require 'rails_helper'

describe Macros::ExecutionService, type: :service do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }
  let(:macro) do
    create(:macro, account: account, created_by: user, updated_by: user,
                   actions: [{ 'action_name' => 'resolve_conversation', 'action_params' => [] }])
  end

  before do
    create(:inbox_member, user: user, inbox: inbox)
    create(:custom_attribute_definition, account: account, attribute_key: 'priority_level',
                                         attribute_model: 'conversation_attribute')
    account.enable_features('conversation_required_attributes')
    account.update!(conversation_required_attributes: ['priority_level'])
  end

  it 'skips the resolve action when a required attribute is missing' do
    described_class.new(macro, conversation, user).perform

    expect(conversation.reload.status).to eq('open')
  end

  it 'resolves when all required attributes are filled' do
    conversation.update!(custom_attributes: { 'priority_level' => 'high' })

    described_class.new(macro, conversation, user).perform

    expect(conversation.reload.status).to eq('resolved')
  end

  it 'resolves when the feature is disabled' do
    account.disable_features('conversation_required_attributes')

    described_class.new(macro, conversation, user).perform

    expect(conversation.reload.status).to eq('resolved')
  end

  it 'ignores required keys whose attribute definition no longer exists' do
    account.update!(conversation_required_attributes: %w[priority_level deleted_key])
    conversation.update!(custom_attributes: { 'priority_level' => 'high' })

    described_class.new(macro, conversation, user).perform

    expect(conversation.reload.status).to eq('resolved')
  end

  context 'when the macro uses a change_status action' do
    let(:macro) do
      create(:macro, account: account, created_by: user, updated_by: user,
                     actions: [{ 'action_name' => 'change_status', 'action_params' => [status] }])
    end

    context 'with a resolved status' do
      let(:status) { 'resolved' }

      it 'skips the action when a required attribute is missing' do
        described_class.new(macro, conversation, user).perform

        expect(conversation.reload.status).to eq('open')
      end
    end

    context 'with the resolved enum value' do
      let(:status) { Conversation.statuses['resolved'] }

      it 'skips the action when a required attribute is missing' do
        described_class.new(macro, conversation, user).perform

        expect(conversation.reload.status).to eq('open')
      end
    end

    context 'with a status other than resolved' do
      let(:status) { 'pending' }

      it 'applies the status even when a required attribute is missing' do
        described_class.new(macro, conversation, user).perform

        expect(conversation.reload.status).to eq('pending')
      end
    end
  end

  it 'treats a false checkbox value as filled' do
    conversation.update!(custom_attributes: { 'priority_level' => false })

    described_class.new(macro, conversation, user).perform

    expect(conversation.reload.status).to eq('resolved')
  end
end
