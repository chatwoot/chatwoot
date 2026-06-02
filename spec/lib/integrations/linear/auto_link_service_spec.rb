require 'rails_helper'

describe Integrations::Linear::AutoLinkService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:processor) { instance_double(Integrations::Linear::ProcessorService) }
  let(:activity_service) { instance_double(Linear::ActivityMessageService, perform: true) }

  let(:linear_url) { 'https://linear.app/chatwoot/issue/CW-1234/some-slug' }
  let(:identifier) { 'CW-1234' }
  let(:node_id) { 'linear-node-id-1' }
  let(:search_response) do
    { data: [{ 'id' => node_id, 'identifier' => identifier, 'title' => 'Issue title',
               'url' => 'https://linear.app/chatwoot/issue/CW-1234/issue-title' }] }
  end

  before do
    allow(Integrations::Linear::ProcessorService).to receive(:new).with(account: account).and_return(processor)
    allow(Linear::ActivityMessageService).to receive(:new).and_return(activity_service)
    allow(processor).to receive(:linked_issues).and_return({ data: [] })
    allow(processor).to receive(:search_issue).and_return(search_response)
    allow(processor).to receive(:link_issue).and_return({ data: { id: node_id, link_id: 'attachment-1' } })
  end

  def build_private_note(content)
    create(:message,
           account: account,
           inbox: inbox,
           conversation: conversation,
           sender: user,
           message_type: :outgoing,
           private: true,
           content: content)
  end

  describe '#perform' do
    context 'when the message is not a private note' do
      it 'does no work' do
        message = create(:message, account: account, inbox: inbox, conversation: conversation,
                                   sender: user, message_type: :outgoing, private: false,
                                   content: "see #{linear_url}")

        described_class.new(account: account, message: message).perform

        expect(processor).not_to have_received(:linked_issues)
        expect(processor).not_to have_received(:search_issue)
        expect(processor).not_to have_received(:link_issue)
        expect(Linear::ActivityMessageService).not_to have_received(:new)
      end
    end

    context 'when the sender is not a User' do
      it 'does no work' do
        contact = create(:contact, account: account)
        message = create(:message, account: account, inbox: inbox, conversation: conversation,
                                   sender: contact, message_type: :incoming, private: true,
                                   content: "see #{linear_url}")

        described_class.new(account: account, message: message).perform

        expect(processor).not_to have_received(:link_issue)
        expect(Linear::ActivityMessageService).not_to have_received(:new)
      end
    end

    context 'when the private note has no Linear URL' do
      it 'does no work' do
        message = build_private_note('just a regular note with no link')

        described_class.new(account: account, message: message).perform

        expect(processor).not_to have_received(:link_issue)
        expect(Linear::ActivityMessageService).not_to have_received(:new)
      end
    end

    context 'when the issue identifier is already linked from this conversation' do
      it 'skips silently' do
        message = build_private_note("see #{linear_url}")
        allow(processor).to receive(:linked_issues).and_return(
          { data: [{ 'id' => 'attachment-prev', 'issue' => { 'id' => node_id, 'identifier' => identifier } }] }
        )

        described_class.new(account: account, message: message).perform

        expect(processor).not_to have_received(:search_issue)
        expect(processor).not_to have_received(:link_issue)
        expect(Linear::ActivityMessageService).not_to have_received(:new)
      end
    end

    context 'when Linear search returns no exact match for the identifier' do
      it 'does not link' do
        message = build_private_note("see #{linear_url}")
        allow(processor).to receive(:search_issue).with(identifier).and_return(
          { data: [{ 'id' => 'other', 'identifier' => 'OTHER-1', 'url' => 'https://linear.app/chatwoot/issue/OTHER-1' }] }
        )

        described_class.new(account: account, message: message).perform

        expect(processor).not_to have_received(:link_issue)
        expect(Linear::ActivityMessageService).not_to have_received(:new)
      end
    end

    context 'when the matching issue belongs to a different Linear workspace' do
      it 'does not link' do
        message = build_private_note("see #{linear_url}")
        allow(processor).to receive(:search_issue).with(identifier).and_return(
          { data: [{ 'id' => node_id, 'identifier' => identifier,
                     'url' => 'https://linear.app/other-workspace/issue/CW-1234' }] }
        )

        described_class.new(account: account, message: message).perform

        expect(processor).not_to have_received(:link_issue)
        expect(Linear::ActivityMessageService).not_to have_received(:new)
      end
    end

    context 'when Linear search returns an error' do
      it 'does not link' do
        message = build_private_note("see #{linear_url}")
        allow(processor).to receive(:search_issue).with(identifier).and_return({ error: 'boom' })

        described_class.new(account: account, message: message).perform

        expect(processor).not_to have_received(:link_issue)
        expect(Linear::ActivityMessageService).not_to have_received(:new)
      end
    end

    context 'when link_issue returns an error' do
      it 'does not post the activity message' do
        message = build_private_note("see #{linear_url}")
        allow(processor).to receive(:link_issue).and_return({ error: 'nope' })

        described_class.new(account: account, message: message).perform

        expect(Linear::ActivityMessageService).not_to have_received(:new)
      end
    end

    context 'when the private note contains a Linear URL' do
      it 'links the issue and posts an activity message' do
        message = build_private_note("Found it: #{linear_url}")

        described_class.new(account: account, message: message).perform

        expect(processor).to have_received(:link_issue).with(
          a_string_matching(%r{/conversations/#{conversation.display_id}\z}),
          node_id,
          anything,
          user
        )
        expect(Linear::ActivityMessageService).to have_received(:new).with(
          conversation: conversation,
          action_type: :issue_linked,
          user: user,
          issue_data: { id: identifier }
        )
        expect(activity_service).to have_received(:perform)
      end

      it 'links only the first Linear URL when multiple are present' do
        second_url = 'https://linear.app/chatwoot/issue/CW-9999'
        message = build_private_note("see #{linear_url} and #{second_url}")

        described_class.new(account: account, message: message).perform

        expect(processor).to have_received(:search_issue).with(identifier).once
        expect(processor).not_to have_received(:search_issue).with('CW-9999')
      end
    end
  end
end
