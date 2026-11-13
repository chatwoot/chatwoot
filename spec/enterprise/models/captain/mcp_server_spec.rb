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

    it 'rejects a missing enabled value' do
      expect(described_class.new(attributes.merge(enabled: nil))).not_to be_valid
    end

    it 'rejects a token with control characters, which would break the request' do
      expect(described_class.new(attributes.merge(auth_type: 'token', auth_config: { 'token' => "abc\n" }))).not_to be_valid
    end
  end

  describe '.for_enabled_accounts' do
    it 'returns only servers whose account has MCP servers turned on' do
      account.enable_features!(described_class::FEATURE_FLAG)
      on_server = described_class.create!(attributes)
      other_account = create(:account)
      described_class.create!(attributes.merge(account: other_account, assistant: create(:captain_assistant, account: other_account)))

      expect(described_class.for_enabled_accounts).to eq([on_server])
    end
  end

  describe 'status' do
    let(:token_server) { described_class.create!(attributes.merge(auth_type: 'token', auth_config: { 'token' => 'old' })) }
    let(:oauth_server) { described_class.create!(attributes.merge(url: 'https://oauth.example.com/mcp', auth_type: 'oauth')) }

    def run_request(server, &)
      Captain::Mcp::Connection.new(server).track_status(&)
    rescue *Captain::Mcp::Connection::ERRORS
      nil
    end

    it 'starts an OAuth server without credentials and other servers as active' do
      expect(oauth_server).to be_needs_credentials
      expect(token_server).to be_active
    end

    it 'needs credentials once the server rejects the saved ones' do
      run_request(token_server) { raise RubyLLM::UnauthorizedError }

      expect(token_server.reload).to be_needs_credentials
    end

    it 'keeps the status when a request fails for another reason, and records why' do
      run_request(token_server) { raise Faraday::TimeoutError, 'timed out' }

      expect(token_server.reload).to have_attributes(status: 'active', last_error: 'timed out')
    end

    it 'returns to active and clears the error when a request works' do
      run_request(token_server) { raise Faraday::TimeoutError, 'timed out' }
      run_request(token_server) { raise RubyLLM::UnauthorizedError }

      run_request(token_server) { :ok }

      expect(token_server.reload).to have_attributes(status: 'active', last_error: nil)
    end

    it 'returns a token server to active when a new token is saved, and keeps the status on other edits' do
      token_server.credentials_rejected!

      token_server.update!(name: 'Renamed')
      expect(token_server.reload).to be_needs_credentials

      token_server.update!(auth_config: { 'token' => 'new' })
      expect(token_server.reload).to be_active
    end

    it 'does not let a token sent to an OAuth server stand in for signing in' do
      oauth_server.update!(auth_config: { 'token' => 'ignored' })

      expect(oauth_server.reload).to be_needs_credentials
    end

    it 'records a result even when the row no longer passes validation' do
      token_server.update_column(:url, 'http://mcp.example.com/mcp') # rubocop:disable Rails/SkipsModelValidations

      run_request(token_server) { raise RubyLLM::UnauthorizedError }

      expect(token_server.reload).to be_needs_credentials
    end

    it 'writes nothing when a request changes nothing' do
      allow(token_server).to receive(:update_columns).and_call_original

      token_server.credentials_accepted!
      token_server.credentials_rejected!
      token_server.credentials_rejected!

      expect(token_server).to have_received(:update_columns).once
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

    describe 'review states' do
      let(:approved) { { 'same' => definition.call('same'), 'edited' => definition.call('edited'), 'gone' => definition.call('gone') } }
      let(:live) { [definition.call('same'), definition.call('edited', 'Changed'), definition.call('new')] }

      before { server.sync_tools(approved.transform_values { {} }, approved) }

      it 'records how each approved tool compares with a live listing' do
        expect(server).not_to be_needs_review

        server.record_live_tools(live)

        expect(server.tools.reload.to_h { |tool| [tool.name, tool.review_state] })
          .to eq({ 'same' => 'current', 'edited' => 'changed', 'gone' => 'missing' })
        expect(server).to be_needs_review
      end

      it 'marks each live tool from the recorded states' do
        server.record_live_tools(live)

        entries = server.live_tool_entries(live)

        expect(entries[:tools].map { |entry| [entry[:definition]['name'], entry[:approved], entry[:changed]] })
          .to eq([['same', true, false], ['edited', true, true], ['new', false, false]])
        expect(entries[:missing]).to eq(['gone'])
      end

      it 'stops needing review once the admin removes the tools that changed' do
        server.record_live_tools(live)

        server.sync_tools({ 'same' => {} }, {})

        expect(server.reload).not_to be_needs_review
      end

      it 'approves only the version the admin reviewed' do
        server.record_live_tools(live)
        reviewed = Captain::McpTool.definition_digest(definition.call('edited', 'Changed'))
        changed_again = live.map { |tool| tool['name'] == 'edited' ? definition.call('edited', 'Changed again') : tool }

        expect { server.approve_tool('edited', reviewed, changed_again) }.to raise_error(ActiveRecord::RecordInvalid)

        server.approve_tool('edited', reviewed, live)

        expect(server.tools.reload.find_by(name: 'edited')).to have_attributes(review_state: 'current', description: 'Changed')
      end

      it 'tells a tool that was never approved apart from one the server dropped' do
        digest = Captain::McpTool.definition_digest(definition.call('new'))

        expect { server.approve_tool('new', digest, live) }
          .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: new is not approved yet. Select it in the tools list to approve it.')
        expect { described_class.find(server.id).approve_tool('gone', digest, live) }
          .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The server no longer offers gone.')
      end
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
