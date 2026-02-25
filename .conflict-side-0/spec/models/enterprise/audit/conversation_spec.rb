require 'rails_helper'

RSpec.describe 'Conversation Audit', type: :model do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    # Enable auditing for conversations
    conversation.class.send(:include, Enterprise::Audit::Conversation) if defined?(Enterprise::Audit::Conversation)
  end

  describe 'audit logging on destroy' do
    it 'creates an audit log when conversation is destroyed' do
      skip 'Enterprise audit module not available' unless defined?(Enterprise::Audit::Conversation)

      expect do
        conversation.destroy!
      end.to change(Audited::Audit, :count).by(1)

      audit = Audited::Audit.last
      expect(audit.auditable_type).to eq('Conversation')
      expect(audit.action).to eq('destroy')
      expect(audit.auditable_id).to eq(conversation.id)
    end

    it 'does not create audit log for other actions by default' do
      skip 'Enterprise audit module not available' unless defined?(Enterprise::Audit::Conversation)

      expect do
        conversation.update!(priority: 'high')
      end.not_to(change(Audited::Audit, :count))
    end
  end
end
