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

    context 'with stored values' do
      let(:inbox) { create(:inbox, account: account) }
      let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: create(:contact, account: account)) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact) }
      let(:tool_context) { Struct.new(:state).new({ account_id: account.id, conversation: { id: conversation.id } }) }
      let(:source_metadata) do
        { 'source' => 'github', 'repository' => 'chatwoot/tools', 'path' => 'stripe', 'tool_id' => 'find_customer', 'revision' => 'a' * 40,
          'version' => '1.0.0', 'manifest_digest' => "sha256:#{'b' * 64}", 'installation_id' => SecureRandom.uuid }
      end
      let(:email_param) { { 'name' => 'email', 'type' => 'string', 'description' => 'Email', 'source' => 'verified.email' } }
      let(:customer_param) { { 'name' => 'customer', 'type' => 'string', 'description' => 'Customer', 'source' => 'stored.customer_id' } }
      let(:find_tool) do
        create(:captain_custom_tool, account: account, assistant: assistant, source_metadata: source_metadata, response_template: nil,
                                     endpoint_url: 'https://example.com/customers?email={{ email | url_encode }}',
                                     param_schema: [email_param], stores: { 'customer_id' => 'data[*].id' })
      end
      let(:list_tool) do
        create(:captain_custom_tool, account: account, assistant: assistant, response_template: nil,
                                     source_metadata: source_metadata.merge('tool_id' => 'list_invoices'),
                                     endpoint_url: 'https://example.com/invoices?customer={{ customer }}', param_schema: [customer_param])
      end
      let(:customers) { [{ id: 'cus_jane' }] }

      before do
        allow(Captain::EmailVerification).to receive(:new).with(conversation)
                                                          .and_return(instance_double(Captain::EmailVerification, verified_email: 'jane@example.com'))
        stub_request(:get, %r{\Ahttps://example.com/customers}).to_return(status: 200, body: { data: customers }.to_json)
        stub_request(:get, %r{\Ahttps://example.com/invoices}).to_return(status: 200, body: '{"data": []}')
      end

      it 'refuses a stored value parameter before the lookup has run, and names the tool that looks it up' do
        find_tool
        result = described_class.new(assistant, list_tool).perform(tool_context, customer: 'cus_jane')

        expect(result).to include('No customer_id has been found for this customer yet', "Call #{find_tool.slug} first")
        expect(WebMock).not_to have_requested(:get, %r{\Ahttps://example.com/invoices})
      end

      it 'fills the one stored value' do
        described_class.new(assistant, find_tool).perform(tool_context)

        described_class.new(assistant, list_tool).perform(tool_context)

        expect(WebMock).to have_requested(:get, 'https://example.com/invoices?customer=cus_jane')
      end

      it 'refuses a value that was not stored for this customer' do
        described_class.new(assistant, find_tool).perform(tool_context)

        result = described_class.new(assistant, list_tool).perform(tool_context, customer: 'cus_bob')

        expect(result).to include('customer must be one of: cus_jane')
        expect(WebMock).not_to have_requested(:get, %r{\Ahttps://example.com/invoices})
      end

      context 'when the lookup returns several values' do
        let(:customers) { [{ id: 'cus_jane' }, { id: 'cus_jane_2' }] }

        it 'takes the one the model picks' do
          described_class.new(assistant, find_tool).perform(tool_context)

          described_class.new(assistant, list_tool).perform(tool_context, customer: 'cus_jane_2')

          expect(WebMock).to have_requested(:get, 'https://example.com/invoices?customer=cus_jane_2')
        end

        it 'asks the model to pick one when it passes none' do
          described_class.new(assistant, find_tool).perform(tool_context)

          expect(described_class.new(assistant, list_tool).perform(tool_context)).to include('customer must be one of: cus_jane, cus_jane_2')
        end
      end

      it 'does not store values from a tool that takes a value from the model' do
        # Skips validation on purpose, to check the guard that runs when a response comes back
        find_tool.update_columns(param_schema: [email_param, { 'name' => 'query', 'type' => 'string', 'description' => 'Search' }]) # rubocop:disable Rails/SkipsModelValidations
        described_class.new(assistant, find_tool.reload).perform(tool_context, query: 'bob')

        expect(described_class.new(assistant, list_tool).perform(tool_context)).to include('No customer_id has been found')
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
