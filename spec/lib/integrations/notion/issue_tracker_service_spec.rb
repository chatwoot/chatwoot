require 'rails_helper'

RSpec.describe Integrations::Notion::IssueTrackerService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:issue_tracker_settings) do
    {
      'data_source_id' => 'data-source-1',
      'title_property' => 'Name'
    }
  end
  let(:hook) do
    create(
      :integrations_hook,
      account: account,
      app_id: 'notion',
      access_token: 'notion_access_token',
      settings: { 'issue_tracker' => issue_tracker_settings }
    )
  end
  let(:service) do
    hook
    described_class.new(account: account)
  end
  let(:conversation_url) { "https://app.chatwoot.test/app/accounts/#{account.id}/conversations/#{conversation.display_id}" }
  let(:request_body) { {} }

  describe '#create_issue' do
    it 'creates a Notion page with required properties and stores the issue link' do
      stub_notion_page_request(id: 'page-1', url: 'https://notion.so/page-1')

      result = nil
      with_modified_env FRONTEND_URL: 'https://app.chatwoot.test' do
        result = service.create_issue({ title: 'Refund request', conversation_id: conversation.display_id }, agent)
      end

      expect(result[:data]).to include(
        id: 'page-1',
        title: 'Refund request',
        url: 'https://notion.so/page-1'
      )
      expect(request_body).to eq(minimal_page_payload)

      issue_link = Integrations::IssueLink.last
      expect(issue_link).to have_attributes(
        account_id: account.id,
        conversation_id: conversation.id,
        app_id: 'notion',
        external_id: 'page-1',
        external_url: 'https://notion.so/page-1',
        external_title: 'Refund request'
      )
      expect(issue_link.metadata).to include(
        'data_source_id' => 'data-source-1',
        'created_by' => agent.id,
        'created_by_name' => agent.name
      )
    end

    context 'with optional configured properties' do
      let(:issue_tracker_settings) do
        {
          'data_source_id' => 'data-source-1',
          'title_property' => 'Name',
          'description_property' => 'Description',
          'status_property' => 'Status',
          'priority_property' => 'Priority',
          'label_property' => 'Tags'
        }
      end

      it 'sends configured rich text, status, select priority, and multi-select properties' do
        stub_notion_page_request(id: 'page-2', url: 'https://notion.so/page-2')

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.test' do
          service.create_issue(
            {
              title: 'Export fails',
              description: 'Export fails when invoices include discounts.',
              conversation_id: conversation.display_id,
              state_id: 'In progress',
              priority: 'High',
              label_ids: %w[Billing Exports]
            },
            agent
          )
        end

        expect(request_body['properties']).to include(optional_page_properties)
        expect(request_body['children'].first).to eq(description_child)
      end

      it 'uses a number value for numeric priorities' do
        stub_notion_page_request(id: 'page-3', url: 'https://notion.so/page-3')

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.test' do
          service.create_issue(
            { title: 'Numeric priority', conversation_id: conversation.display_id, priority: '2' },
            agent
          )
        end

        expect(request_body['properties']['Priority']).to eq('number' => 2)
      end
    end

    it 'returns Notion API errors without storing a link' do
      stub_request(:post, 'https://api.notion.com/v1/pages')
        .to_return(
          status: 400,
          body: { object: 'error', message: 'Invalid property' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = service.create_issue({ title: 'Refund request', conversation_id: conversation.display_id }, agent)

      expect(result).to eq(error: { 'object' => 'error', 'message' => 'Invalid property' })
      expect(Integrations::IssueLink.count).to eq(0)
    end
  end

  describe '#linked_issues' do
    it 'returns local Notion links for the conversation sorted newest first' do
      older_link = create(
        :integrations_issue_link,
        account: account,
        conversation: conversation,
        app_id: 'notion',
        external_id: 'older-page',
        external_title: 'Older issue',
        created_at: 2.days.ago
      )
      newer_link = create(
        :integrations_issue_link,
        account: account,
        conversation: conversation,
        app_id: 'notion',
        external_id: 'newer-page',
        external_title: 'Newer issue',
        created_at: 1.hour.ago
      )
      create(:integrations_issue_link, account: account, conversation: conversation, app_id: 'linear', external_id: 'linear-issue')
      create(
        :integrations_issue_link,
        account: account,
        conversation: create(:conversation, account: account),
        app_id: 'notion',
        external_id: 'other-page'
      )

      result = service.linked_issues(conversation.display_id)

      expect(result[:data].pluck(:id)).to eq([newer_link.external_id, older_link.external_id])
      expect(result[:data].pluck(:title)).to eq(['Newer issue', 'Older issue'])
    end
  end

  def stub_notion_page_request(id:, url:)
    stub_request(:post, 'https://api.notion.com/v1/pages')
      .with do |request|
        request_body.replace(JSON.parse(request.body))
        true
      end
      .to_return(
        status: 200,
        body: { id: id, url: url }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def minimal_page_payload
    {
      'parent' => { 'data_source_id' => 'data-source-1' },
      'properties' => {
        'Name' => { 'title' => [text_payload('Refund request')] }
      },
      'children' => [
        paragraph_payload(text_payload("Created by #{agent.name}")),
        paragraph_payload(
          text_payload('Chatwoot conversation: '),
          text_payload(conversation_url, link: conversation_url)
        )
      ]
    }
  end

  def optional_page_properties
    {
      'Name' => { 'title' => [text_payload('Export fails')] },
      'Description' => { 'rich_text' => [text_payload('Export fails when invoices include discounts.')] },
      'Status' => { 'status' => { 'name' => 'In progress' } },
      'Priority' => { 'select' => { 'name' => 'High' } },
      'Tags' => { 'multi_select' => [{ 'name' => 'Billing' }, { 'name' => 'Exports' }] }
    }
  end

  def description_child
    paragraph_payload(text_payload('Export fails when invoices include discounts.'))
  end

  def paragraph_payload(*rich_text)
    {
      'object' => 'block',
      'type' => 'paragraph',
      'paragraph' => { 'rich_text' => rich_text }
    }
  end

  def text_payload(content, link: nil)
    text = { 'content' => content }
    text['link'] = { 'url' => link } if link
    { 'type' => 'text', 'text' => text }
  end
end
