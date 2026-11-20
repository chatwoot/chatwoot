require 'rails_helper'

RSpec.describe Captain::Tools::PublicHttpTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:custom_tool) { create(:captain_custom_tool, account: account) }
  let(:tool) { described_class.new(assistant, custom_tool) }
  let(:tool_context) { Struct.new(:state).new({}) }

  describe '#perform' do
    context 'when a parameter takes a verified value' do
      let(:inbox) { create(:inbox, account: account) }
      let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: create(:contact, account: account)) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact) }
      let(:state) { { account_id: account.id, conversation: { id: conversation.id }, contact_inbox: { id: contact_inbox.id, hmac_verified: false } } }
      let(:tool_context) { Struct.new(:state).new(state) }
      let(:verified_email) { 'jane@example.com' }
      let(:request_stub) { stub_request(:get, %r{\Ahttps://example.com/customers}).to_return(status: 200, body: '{"found": true}') }
      let(:email_param) { { 'name' => 'email', 'type' => 'string', 'description' => 'Email', 'source' => 'verified.email' } }

      before do
        custom_tool.update!(http_method: 'GET', endpoint_url: 'https://example.com/customers?email={{ email | url_encode }}',
                            param_schema: [email_param], response_template: nil)
        request_stub
        verification = instance_double(Captain::EmailVerification, verified_email: verified_email)
        allow(Captain::EmailVerification).to receive(:new).with(conversation).and_return(verification)
      end

      it 'sends the verified email' do
        expect(tool.perform(tool_context)).to eq('{"found": true}')
        expect(WebMock).to have_requested(:get, 'https://example.com/customers?email=jane%40example.com')
      end

      it 'replaces an email the model passes with the verified one' do
        tool.perform(tool_context, email: ' JANE@example.com ')

        expect(WebMock).to have_requested(:get, 'https://example.com/customers?email=jane%40example.com')
      end

      it 'sends the verified email when the model passes another one' do
        tool.perform(tool_context, email: 'victim@example.com')

        expect(WebMock).to have_requested(:get, 'https://example.com/customers?email=jane%40example.com')
        expect(WebMock).not_to have_requested(:get, 'https://example.com/customers?email=victim%40example.com')
      end

      it 'is blocked for a customer without a verified email, with no setting turned on' do
        unverified = instance_double(Captain::EmailVerification, verified_email: nil)
        allow(Captain::EmailVerification).to receive(:new).with(conversation).and_return(unverified)

        expect(tool.perform(tool_context)).to include('has not verified an email')
        expect(request_stub).not_to have_been_requested
      end
    end

    context 'when the tool requires email verification' do
      let(:inbox) { create(:inbox, account: account) }
      let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: create(:contact, account: account)) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact) }
      let(:state) { { account_id: account.id, conversation: { id: conversation.id }, contact_inbox: { id: contact_inbox.id, hmac_verified: false } } }
      let(:tool_context) { Struct.new(:state).new(state) }
      let(:verified_email) { nil }

      before do
        custom_tool.update!(http_method: 'GET', endpoint_url: 'https://example.com/orders/123', response_template: nil,
                            settings: { 'requires_email_verification' => true })
        stub_request(:get, 'https://example.com/orders/123').to_return(status: 200, body: '{"status": "success"}')
        verification = instance_double(Captain::EmailVerification, verified_email: verified_email)
        allow(Captain::EmailVerification).to receive(:new).with(conversation).and_return(verification)
      end

      it 'does not call the endpoint for a customer without a verified email' do
        result = tool.perform(tool_context)

        expect(result).to include('has not verified an email')
        expect(WebMock).not_to have_requested(:get, 'https://example.com/orders/123')
      end

      it 'does not accept HMAC verification in place of a verified email' do
        contact_inbox.update!(hmac_verified: true)
        state[:contact_inbox][:hmac_verified] = true

        tool.perform(tool_context)

        expect(WebMock).not_to have_requested(:get, 'https://example.com/orders/123')
      end

      it 'does not call the endpoint when the run has no conversation' do
        state.delete(:conversation)

        result = tool.perform(tool_context)

        expect(result).to include('has not verified an email')
        expect(WebMock).not_to have_requested(:get, 'https://example.com/orders/123')
      end

      it 'does not look up a conversation from another account' do
        other_conversation = create(:conversation)
        allow(Captain::EmailVerification).to receive(:new).with(other_conversation)
                                                          .and_return(instance_double(Captain::EmailVerification, verified_email: 'jane@example.com'))
        state[:conversation][:id] = other_conversation.id

        tool.perform(tool_context)

        expect(WebMock).not_to have_requested(:get, 'https://example.com/orders/123')
      end

      context 'when the customer has verified an email' do
        let(:verified_email) { 'jane@example.com' }

        it 'calls the endpoint' do
          result = tool.perform(tool_context)

          expect(result).to eq('{"status": "success"}')
          expect(WebMock).to have_requested(:get, 'https://example.com/orders/123')
        end
      end

      context 'when the request takes an email from the model' do
        let(:verified_email) { 'jane@example.com' }
        let(:request_stub) { stub_request(:get, %r{\Ahttps://example.com/customers}).to_return(status: 200, body: '{"found": true}') }

        before do
          custom_tool.update!(endpoint_url: 'https://example.com/customers?email={{ email | url_encode }}&note={{ note | url_encode }}',
                              param_schema: [{ 'name' => 'email', 'type' => 'string', 'description' => 'Customer email' },
                                             { 'name' => 'note', 'type' => 'string', 'description' => 'Note' }])
          request_stub
        end

        # Binding the email is what a verified email parameter is for. The setting alone only requires a verified customer.
        it 'runs with the email the model passes once the customer has verified one' do
          tool.perform(tool_context, email: 'someone@example.com')

          expect(WebMock).to have_requested(:get, 'https://example.com/customers?email=someone%40example.com&note=')
        end
      end

      it 'does not block a tool that does not require verification' do
        custom_tool.update!(settings: {})

        expect(tool.perform(tool_context)).to eq('{"status": "success"}')
      end
    end

    it 'ignores a run state that says an admin or an agent is the user' do
      custom_tool.update!(settings: { 'requires_email_verification' => true })
      stub_request(:get, %r{\Ahttps://example.com}).to_return(status: 200, body: '{}')

      result = tool.perform(Struct.new(:state).new({ source: 'playground' }))

      expect(result).to include('has not verified an email')
      expect(WebMock).not_to have_requested(:get, %r{\Ahttps://example.com})
    end
  end
end
