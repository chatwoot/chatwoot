require 'rails_helper'

RSpec.describe Captain::McpServer do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:attributes) { { account: account, assistant: assistant, name: 'Invoicely', url: 'https://mcp.example.com/mcp' } }

  describe 'validations' do
    it 'accepts an HTTPS URL' do
      expect(described_class.new(attributes)).to be_valid
    end

    it 'rejects a URL that RubyLLM cannot connect to' do
      with_credentials = described_class.new(attributes.merge(url: 'https://user:pass@mcp.example.com/mcp'))
      with_braces = described_class.new(attributes.merge(url: 'https://{{tenant}}.example.com/mcp'))

      expect(with_credentials).not_to be_valid
      expect(with_credentials.errors[:endpoint_url]).to include('cannot contain a username or password')
      expect(with_braces).not_to be_valid
      expect(with_braces.errors[:endpoint_url]).to include('must be a valid URL')
    end

    it 'rejects a URL that is not HTTPS' do
      server = described_class.new(attributes.merge(url: 'http://mcp.example.com/mcp'))

      expect(server).not_to be_valid
      expect(server.errors[:endpoint_url]).to include('must use HTTPS protocol')
    end

    it 'rejects the same URL twice on one assistant' do
      described_class.create!(attributes)

      expect(described_class.new(attributes.merge(name: 'Copy'))).not_to be_valid
    end

    it 'accepts Authorization and a custom header for the token' do
      %w[Authorization X-API-Key].each do |header|
        expect(described_class.new(attributes.merge(auth_type: 'token', auth_header: header))).to be_valid
      end
    end

    it 'rejects a token header that the MCP connection sets itself' do
      %w[Content-Type Accept Host Mcp-Session-Id MCP-Protocol-Version].each do |header|
        server = described_class.new(attributes.merge(auth_type: 'token', auth_header: header))

        expect(server).not_to be_valid
        expect(server.errors[:auth_header]).to include("#{header} is set by the MCP connection and cannot carry the token")
      end
    end

    it 'rejects a header name with characters a header cannot have' do
      expect(described_class.new(attributes.merge(auth_type: 'token', auth_header: 'Api Key'))).not_to be_valid
    end

    it 'rejects a token with control characters, which would break the request' do
      expect(described_class.new(attributes.merge(auth_type: 'token', auth_config: { 'token' => "abc\n" }))).not_to be_valid
    end
  end

  describe 'status' do
    it 'starts an OAuth server as needing sign-in and other servers as active' do
      oauth = described_class.create!(attributes.merge(auth_type: 'oauth'))
      token = described_class.create!(attributes.merge(url: 'https://other.example.com/mcp', auth_type: 'token'))

      expect(oauth).to be_needs_sign_in
      expect(token).to be_active
    end

    it 'clears the error when a new token is saved, and keeps it on other edits' do
      server = described_class.create!(attributes.merge(auth_type: 'token', auth_config: { 'token' => 'old' }))
      server.record_failure(RubyLLM::UnauthorizedError.new)

      server.update!(name: 'Renamed')
      expect(server.reload).to be_error

      server.update!(auth_config: { 'token' => 'new' })
      expect(server.reload).to have_attributes(status: 'active', last_error: nil)
    end

    describe '#record_failure' do
      it 'asks an OAuth server to sign in again when the server rejects it' do
        server = described_class.create!(attributes.merge(auth_type: 'oauth'))
        server.record_success

        server.record_failure(RubyLLM::UnauthorizedError.new)

        expect(server.reload).to be_needs_sign_in
      end

      it 'tells a token server that its token was rejected' do
        server = described_class.create!(attributes.merge(auth_type: 'token'))

        server.record_failure(RubyLLM::UnauthorizedError.new)

        expect(server.reload).to have_attributes(status: 'error', last_error: I18n.t('captain.mcp_server.token_rejected'))
      end

      it 'tells a server without sign-in that it now asks for a token' do
        server = described_class.create!(attributes)

        server.record_failure(RubyLLM::UnauthorizedError.new)

        expect(server.reload).to have_attributes(status: 'error', last_error: I18n.t('captain.mcp_server.token_required'))
      end

      it 'records any other failure with its message' do
        server = described_class.create!(attributes.merge(auth_type: 'oauth'))

        server.record_failure(Faraday::TimeoutError.new('timed out'))

        expect(server.reload).to have_attributes(status: 'error', last_error: 'timed out')
      end

      it 'records the failure even when the row no longer passes validation' do
        server = described_class.create!(attributes)
        server.update_column(:url, 'http://mcp.example.com/mcp') # rubocop:disable Rails/SkipsModelValidations

        server.record_failure(Faraday::ConnectionFailed.new('refused'))

        expect(server.reload).to be_error
      end
    end

    it 'records a success by clearing the last error' do
      server = described_class.create!(attributes)
      server.record_failure(Faraday::TimeoutError.new('timed out'))

      server.record_success

      expect(server.reload).to have_attributes(status: 'active', last_error: nil)
    end
  end

  describe 'OAuth state' do
    it 'finds the server a sign-in started for, only once' do
      server = described_class.create!(attributes.merge(auth_type: 'oauth'))
      server.remember_oauth_state('state-123')

      expect(described_class.for_oauth_state('state-123')).to eq(server)
      expect(described_class.for_oauth_state('state-123')).to be_nil
    end

    it 'finds nothing for a state it never saw' do
      expect(described_class.for_oauth_state('unknown')).to be_nil
    end
  end

  describe 'tools' do
    let(:server) { described_class.create!(attributes) }
    let(:schema) { { 'type' => 'object', 'properties' => { 'email' => { 'type' => 'string' } } } }
    let(:definition) do
      ->(name, description = 'Look up') { { 'name' => name, 'description' => description, 'input_schema' => schema, 'read_only' => true } }
    end

    describe '#sync_tools' do
      it 'approves a new tool and pins it to the live definition' do
        server.sync_tools({ 'get_customer' => {} }, { 'get_customer' => definition.call('get_customer') })

        tool = server.tools.sole
        expect(tool.description).to eq('Look up')
        expect(tool.approval_current?(definition.call('get_customer'))).to be(true)
      end

      it 'keeps the approved definition when the server changed it, and updates the fields sent' do
        server.sync_tools({ 'get_customer' => {} }, { 'get_customer' => definition.call('get_customer') })

        server.sync_tools({ 'get_customer' => { 'enabled' => false } }, { 'get_customer' => definition.call('get_customer', 'Changed') })

        tool = server.tools.sole
        expect(tool.description).to eq('Look up')
        expect(tool.enabled).to be(false)
      end

      it 'removes the approved tools the selection leaves out' do
        live = { 'get_customer' => definition.call('get_customer'), 'list_invoices' => definition.call('list_invoices') }
        server.sync_tools({ 'get_customer' => {}, 'list_invoices' => {} }, live)

        server.sync_tools({ 'list_invoices' => {} }, {})

        expect(server.tools.map(&:name)).to eq(['list_invoices'])
      end

      it 'rejects a new tool the server does not offer, and changes nothing' do
        server.sync_tools({ 'get_customer' => {} }, { 'get_customer' => definition.call('get_customer') })

        expect { server.sync_tools({ 'list_invoices' => {} }, {}) }
          .to raise_error(ActiveRecord::RecordInvalid, /The server no longer offers list_invoices/)
        expect(server.tools.reload.map(&:name)).to eq(['get_customer'])
      end

      it 'saves no tool when one of them is invalid' do
        live = { 'get_customer' => definition.call('get_customer'), 'list_invoices' => definition.call('list_invoices') }
        invalid_sources = { 'param_sources' => { 'email' => { 'source' => 'verified.phone' } } }

        expect { server.sync_tools({ 'get_customer' => {}, 'list_invoices' => invalid_sources }, live) }
          .to raise_error(ActiveRecord::RecordInvalid)
        expect(server.tools.reload).to be_empty
      end
    end

    it 'lists the selected tools that are not approved yet' do
      server.sync_tools({ 'get_customer' => {} }, { 'get_customer' => definition.call('get_customer') })

      expect(server.new_tool_names(%w[get_customer list_invoices])).to eq(['list_invoices'])
    end

    it 'compares the live tools with the approved ones' do
      approved = { 'same' => definition.call('same'), 'edited' => definition.call('edited'), 'gone' => definition.call('gone') }
      server.sync_tools(approved.transform_values { {} }, approved)
      live = [definition.call('same'), definition.call('edited', 'Changed'), definition.call('new')]

      comparison = server.compare_live_tools(live)

      expect(comparison[:tools].map { |entry| [entry[:definition]['name'], entry[:approved], entry[:changed]] })
        .to eq([['same', true, false], ['edited', true, true], ['new', false, false]])
      expect(comparison[:missing]).to eq(['gone'])
    end

    it 'offers Captain only the enabled tools of an enabled server' do
      live = { 'get_customer' => definition.call('get_customer'), 'list_invoices' => definition.call('list_invoices') }
      server.sync_tools({ 'get_customer' => {}, 'list_invoices' => { 'enabled' => false } }, live)

      expect(server.available_tools.map(&:name)).to eq(['get_customer'])

      server.update!(enabled: false)
      expect(server.available_tools).to be_empty
    end
  end
end
