require 'rails_helper'

RSpec.describe MessageTemplates::Template::EmailCollect do
  describe '#perform' do
    let(:conversation) { create(:conversation) }

    it 'creates the email collect messages' do
      expect do
        described_class.new(conversation: conversation).perform
      end.to change { conversation.messages.count }.by(2)
    end
  end

  describe '.perform_after_handoff_if_applicable' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account, enable_email_collect: true) }
    let(:contact) { create(:contact, account: account, email: nil) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, status: :open) }

    it 'asks for an email when the handed-off conversation is unassigned' do
      expect do
        described_class.perform_after_handoff_if_applicable(conversation)
      end.to change { conversation.messages.template.count }.by(2)

      expect(conversation.messages.template.order(:id).pluck(:content_type)).to eq(%w[text input_email])
    end

    it 'does not ask for an email when an agent is assigned' do
      conversation.update!(assignee: create(:user, account: account))

      expect do
        described_class.perform_after_handoff_if_applicable(conversation)
      end.not_to(change { conversation.messages.count })
    end

    it 'does not ask for an email when collection is disabled' do
      inbox.update!(enable_email_collect: false)

      expect do
        described_class.perform_after_handoff_if_applicable(conversation)
      end.not_to(change { conversation.messages.count })
    end

    it 'does not ask for an email outside the web widget' do
      email_inbox = create(:inbox, :with_email, account: account, enable_email_collect: true)
      email_conversation = create(:conversation, account: account, inbox: email_inbox, contact: contact, status: :open)

      expect do
        described_class.perform_after_handoff_if_applicable(email_conversation)
      end.not_to(change { email_conversation.messages.count })
    end

    it 'does not ask for an email when the contact already has one' do
      contact.update!(email: 'customer@example.com')

      expect do
        described_class.perform_after_handoff_if_applicable(conversation)
      end.not_to(change { conversation.messages.count })
    end

    it 'does not ask for an email more than once' do
      described_class.perform_after_handoff_if_applicable(conversation)

      expect do
        described_class.perform_after_handoff_if_applicable(conversation)
      end.not_to(change { conversation.messages.count })
    end

    it 'does not ask for an email on campaign conversations' do
      conversation.update!(campaign: create(:campaign, account: account, inbox: inbox))

      expect do
        described_class.perform_after_handoff_if_applicable(conversation)
      end.not_to(change { conversation.messages.count })
    end

    it 'does not interrupt a completed handoff when the eligibility check fails' do
      error = StandardError.new('database unavailable')
      exception_tracker = instance_double(ChatwootExceptionTracker, capture_exception: true)
      allow(Conversation).to receive(:transaction).and_raise(error)
      expect(ChatwootExceptionTracker).to receive(:new).with(error, account: account).and_return(exception_tracker)

      expect do
        described_class.perform_after_handoff_if_applicable(conversation)
      end.not_to raise_error
    end
  end
end
