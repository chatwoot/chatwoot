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
      let(:state) { { account_id: account.id, channel_type: 'Channel::WebWidget', contact_inbox: { id: contact_inbox.id, hmac_verified: false } } }
      let(:tool_context) { Struct.new(:state).new(state) }
      let(:verified_email) { 'jane@example.com' }
      let(:request_stub) { stub_request(:get, %r{\Ahttps://example.com/customers}).to_return(status: 200, body: '{"found": true}') }
      let(:email_param) { { 'name' => 'email', 'type' => 'string', 'description' => 'Email', 'source' => 'verified.email' } }

      before do
        custom_tool.update!(http_method: 'GET', endpoint_url: 'https://example.com/customers?email={{ email | url_encode }}',
                            param_schema: [email_param], response_template: nil)
        request_stub
        verification = instance_double(Captain::EmailVerification, verified_email: verified_email)
        allow(Captain::EmailVerification).to receive(:new).with(contact_inbox).and_return(verification)
      end

      it 'sends the verified email' do
        expect(tool.perform(tool_context)).to eq('{"found": true}')
        expect(WebMock).to have_requested(:get, 'https://example.com/customers?email=jane%40example.com')
      end

      it 'replaces an email the model passes with the verified one' do
        tool.perform(tool_context, email: ' JANE@example.com ')

        expect(WebMock).to have_requested(:get, 'https://example.com/customers?email=jane%40example.com')
      end

      it 'refuses when the model passes another email' do
        result = tool.perform(tool_context, email: 'victim@example.com')

        expect(result).to include('only run for jane@example.com')
        expect(request_stub).not_to have_been_requested
      end

      it 'is blocked for a customer without a verified email, with no setting turned on' do
        unverified = instance_double(Captain::EmailVerification, verified_email: nil)
        allow(Captain::EmailVerification).to receive(:new).with(contact_inbox).and_return(unverified)

        expect(tool.perform(tool_context)).to include('has not verified an email')
        expect(request_stub).not_to have_been_requested
      end
    end

    context 'when the tool requires email verification' do
      let(:inbox) { create(:inbox, account: account) }
      let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: create(:contact, account: account)) }
      let(:state) { { account_id: account.id, channel_type: 'Channel::WebWidget', contact_inbox: { id: contact_inbox.id, hmac_verified: false } } }
      let(:tool_context) { Struct.new(:state).new(state) }
      let(:verified_email) { nil }

      before do
        custom_tool.update!(http_method: 'GET', endpoint_url: 'https://example.com/orders/123', response_template: nil,
                            settings: { 'requires_email_verification' => true })
        stub_request(:get, 'https://example.com/orders/123').to_return(status: 200, body: '{"status": "success"}')
        verification = instance_double(Captain::EmailVerification, verified_email: verified_email)
        allow(Captain::EmailVerification).to receive(:new).with(contact_inbox).and_return(verification)
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

      it 'does not call the endpoint when the conversation has no contact inbox' do
        state.delete(:contact_inbox)

        result = tool.perform(tool_context)

        expect(result).to include('has not verified an email')
        expect(WebMock).not_to have_requested(:get, 'https://example.com/orders/123')
      end

      it 'does not look up a contact inbox from another account' do
        other_contact_inbox = create(:contact_inbox)
        allow(Captain::EmailVerification).to receive(:new).with(other_contact_inbox)
                                                          .and_return(instance_double(Captain::EmailVerification, verified_email: 'jane@example.com'))
        state[:contact_inbox][:id] = other_contact_inbox.id

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

        it 'runs with the verified email, whatever its case' do
          tool.perform(tool_context, email: ' Jane@Example.com ')

          expect(request_stub).to have_been_requested
        end

        it 'does not run with another email' do
          result = tool.perform(tool_context, email: 'victim@example.com')

          expect(result).to include('only run for jane@example.com')
          expect(request_stub).not_to have_been_requested
        end

        it 'runs a tool that is not gated with any email, even after the customer verified one' do
          custom_tool.update!(settings: {})

          tool.perform(tool_context, email: 'someone@example.com')

          expect(request_stub).to have_been_requested
        end

        it 'runs with the verified email inside a sentence' do
          tool.perform(tool_context, email: 'jane@example.com', note: 'Contact jane@example.com. Or (jane@example.com)!')

          expect(request_stub).to have_been_requested
        end

        it 'does not run with another email inside a longer value' do
          tool.perform(tool_context, email: 'jane@example.com', note: 'also check <victim@example.com>')

          expect(request_stub).not_to have_been_requested
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
