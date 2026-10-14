require 'rails_helper'

RSpec.describe Captain::Tools::CopilotHttpTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, identifier: 'user_42') }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact) }
  let(:state) { { account_id: account.id, source: 'copilot_reply_suggestion', contact_inbox: { id: contact_inbox.id } } }
  let(:tool_context) { Struct.new(:state).new(state) }
  let(:email_param) { { 'name' => 'email', 'type' => 'string', 'description' => 'Email', 'source' => 'verified.email' } }
  let(:user_param) { { 'name' => 'user_id', 'type' => 'string', 'description' => 'User ID', 'source' => 'verified.identifier' } }
  let(:custom_tool) do
    create(:captain_custom_tool, account: account, http_method: 'GET', response_template: nil,
                                 endpoint_url: 'https://example.com/customers?email={{ email | url_encode }}&user={{ user_id }}',
                                 param_schema: [email_param, user_param])
  end
  let(:tool) { custom_tool.tool(assistant, base_class: described_class) }
  let(:request_stub) { stub_request(:get, %r{\Ahttps://example.com/customers}).to_return(status: 200, body: '{"found": true}') }

  before do
    request_stub
    allow(Captain::EmailVerification).to receive(:new).with(contact_inbox)
                                                      .and_return(instance_double(Captain::EmailVerification, verified_email: 'jane@example.com'))
  end

  it 'shows verified parameters to the model' do
    expect(tool.class.declared_parameters.keys).to contain_exactly(:email, :user_id)
  end

  describe '#perform' do
    it 'uses a value the customer verified and the model value for the rest, and says those were not verified' do
      result = tool.perform(tool_context, email: 'typed@example.com', user_id: 'typed_7')

      expect(WebMock).to have_requested(:get, 'https://example.com/customers?email=jane%40example.com&user=typed_7')
      expect(result).to start_with('{"found": true}')
      expect(result).to include('was not verified by the customer')
    end

    it 'adds no note when every value was verified by the customer' do
      contact_inbox.update!(hmac_verified: true)

      expect(tool.perform(tool_context, email: 'typed@example.com', user_id: 'typed_7')).to eq('{"found": true}')
    end

    it 'uses the values an admin supplies in the playground' do
      result = tool.perform(Struct.new(:state).new({ source: 'playground' }), email: 'test@example.com', user_id: 'u_1')

      expect(WebMock).to have_requested(:get, 'https://example.com/customers?email=test%40example.com&user=u_1')
      expect(result).to include('was not verified by the customer')
    end

    it 'asks for a value the model left out' do
      result = tool.perform(Struct.new(:state).new({ source: 'playground' }), email: 'test@example.com')

      expect(result).to include("needs the customer's user_id")
      expect(request_stub).not_to have_been_requested
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
