require 'rails_helper'

RSpec.describe Captain::Tools::CopilotHttpTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: create(:contact, account: account)) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact) }
  let(:state) { { account_id: account.id, source: 'copilot_reply_suggestion', conversation: { id: conversation.id } } }
  let(:tool_context) { Struct.new(:state).new(state) }
  let(:email_param) { { 'name' => 'email', 'type' => 'string', 'description' => 'Email', 'source' => 'verified.email' } }
  let(:custom_tool) do
    create(:captain_custom_tool, account: account, http_method: 'GET', response_template: nil,
                                 endpoint_url: 'https://example.com/customers?email={{ email | url_encode }}', param_schema: [email_param])
  end
  let(:tool) { custom_tool.tool(assistant, base_class: described_class) }
  let(:request_stub) { stub_request(:get, %r{\Ahttps://example.com/customers}).to_return(status: 200, body: '{"found": true}') }

  before do
    request_stub
    allow(Captain::EmailVerification).to receive(:new).with(conversation)
                                                      .and_return(instance_double(Captain::EmailVerification, verified_email: 'jane@example.com'))
  end

  it 'shows verified parameters to the model' do
    expect(tool.class.declared_parameters.keys).to contain_exactly(:email)
  end

  describe '#perform' do
    it 'uses the email passed, and says when it is not what the customer verified' do
      result = tool.perform(tool_context, email: 'typed@example.com')

      expect(WebMock).to have_requested(:get, 'https://example.com/customers?email=typed%40example.com')
      expect(result).to start_with('{"found": true}')
      expect(result).to include('was not verified by the customer')
    end

    it 'adds no note when the email passed is what the customer verified' do
      expect(tool.perform(tool_context, email: 'Jane@example.com')).to eq('{"found": true}')
    end

    it 'says an empty email is not verified when the customer has verified none' do
      unverified = instance_double(Captain::EmailVerification, verified_email: nil)
      allow(Captain::EmailVerification).to receive(:new).with(conversation).and_return(unverified)

      expect(tool.perform(tool_context, email: ' ')).to include('was not verified by the customer')
    end

    it 'uses the values an admin supplies in the playground' do
      result = tool.perform(Struct.new(:state).new({ source: 'playground' }), email: 'test@example.com')

      expect(WebMock).to have_requested(:get, 'https://example.com/customers?email=test%40example.com')
      expect(result).to include('was not verified by the customer')
    end

    it 'runs a tool that only has the setting turned on, for a customer who has not verified' do
      custom_tool.update!(param_schema: [], endpoint_url: 'https://example.com/customers', settings: { 'requires_email_verification' => true })
      allow(Captain::EmailVerification).to receive(:new).and_return(instance_double(Captain::EmailVerification, verified_email: nil))

      expect(tool.perform(tool_context)).to eq('{"found": true}')
    end

    it 'runs with another email the agent passes for a reply suggestion' do
      custom_tool.update!(param_schema: [{ 'name' => 'email', 'type' => 'string', 'description' => 'Email' }],
                          endpoint_url: 'https://example.com/customers?email={{ email | url_encode }}',
                          settings: { 'requires_email_verification' => true })

      tool.perform(tool_context, email: 'typed@example.com')

      expect(WebMock).to have_requested(:get, 'https://example.com/customers?email=typed%40example.com')
    end
  end
end
