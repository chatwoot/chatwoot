require 'rails_helper'

RSpec.describe Captain::Tools::McpTool do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:tool_context) { Struct.new(:state).new({ account_id: account.id, conversation: { id: conversation.id } }) }
  let(:server) { Captain::McpServer.create!(account: account, assistant: assistant, name: 'Invoicely', url: 'https://mcp.example.com/mcp') }
  let(:schema) do
    { 'type' => 'object', 'required' => %w[email],
      'properties' => { 'email' => { 'type' => 'string' }, 'limit' => { 'type' => 'string' }, 'status' => { 'type' => 'string' } } }
  end
  let(:definition) { { 'name' => 'list_invoices', 'description' => 'List invoices', 'input_schema' => schema, 'read_only' => true } }
  let(:mcp_tool) do
    sources = { 'email' => { 'source' => 'verified.email' }, 'limit' => { 'source' => 'fixed', 'value' => '20' } }
    server.sync_tools({ 'list_invoices' => { 'param_sources' => sources } }, { 'list_invoices' => definition })
    server.tools.first
  end
  let(:ok_result) { instance_double(RubyLLM::MCP::Result, text: 'ok', structured: nil, error?: false) }
  let(:connection) do
    instance_double(Captain::Mcp::Connection, call: ok_result, live_tool_definitions: [definition]).tap do |double|
      allow(double).to receive(:track_status).and_yield
    end
  end
  let(:tool) { Captain::Mcp::AgentTools.build(assistant, mcp_tool, connection, base_class: base_class) }
  let(:verified_email) { 'jane@example.com' }

  before do
    allow(Captain::EmailVerification).to receive(:new).and_return(instance_double(Captain::EmailVerification, verified_email: verified_email))
  end

  describe Captain::Tools::PublicMcpTool do
    let(:base_class) { described_class }

    it 'shows the model only the parameters Chatwoot does not fill' do
      expect(tool.parameters_schema['properties'].keys.map(&:to_s)).to contain_exactly('status')
    end

    it 'sends the verified email and the fixed value, whatever the model passed' do
      tool.perform(tool_context, email: 'mallory@example.com', limit: '500', status: 'open')

      expect(connection).to have_received(:call).with('list_invoices', { email: 'jane@example.com', limit: '20', status: 'open' })
    end

    context 'with a numeric fixed parameter' do
      let(:schema) { super().deep_merge('properties' => { 'limit' => { 'type' => 'number' } }) }

      it 'sends a finite fixed value as a number' do
        mcp_tool.param_sources['limit']['value'] = '2.5'

        tool.perform(tool_context, limit: 500)

        expect(connection).to have_received(:call).with('list_invoices', { email: 'jane@example.com', limit: 2.5 })
      end

      it 'does not call the server when a previously saved fixed value overflows' do
        mcp_tool.param_sources['limit']['value'] = '1e309'

        expect(tool.perform(tool_context)).to eq(Captain::ParamSources::NON_FINITE_FIXED_NUMBER)
        expect(connection).not_to have_received(:call)
      end
    end

    context 'when the customer has not verified an email' do
      let(:verified_email) { nil }

      it 'does not call the server and tells the model to verify the customer' do
        expect(tool.perform(tool_context, status: 'open')).to eq(Captain::ParamSources::UNVERIFIED)
        expect(connection).not_to have_received(:call)
      end
    end
  end

  describe 'a call the server refuses after it listed the tools' do
    let(:base_class) { Captain::Tools::PublicMcpTool }
    let(:connection) { Captain::Mcp::Connection.new(server) }

    before { allow(connection).to receive(:live_tool_definitions).and_return([definition]) }

    it 'marks the server as needing new credentials when the call is unauthorized' do
      allow(connection).to receive(:call).and_raise(RubyLLM::UnauthorizedError)

      expect(tool.perform(tool_context, status: 'open')).to eq('An error occurred while calling the tool')
      expect(server.reload).to be_needs_credentials
    end

    it 'records why when the call fails for another reason' do
      allow(connection).to receive(:call).and_raise(Faraday::ConnectionFailed, 'connection refused')

      tool.perform(tool_context, status: 'open')

      expect(server.reload).to have_attributes(status: 'active', last_error: 'connection refused')
    end

    it 'reads as an error when the answer of a tool that changes nothing stops arriving' do
      allow(connection).to receive(:call).and_raise(Captain::Mcp::Connection::DeadlineExceeded, 'too slow')

      expect(tool.perform(tool_context, status: 'open')).to eq('An error occurred while calling the tool')
    end

    context 'when the tool changes data' do
      let(:definition) { super().merge('read_only' => false) }

      it 'says the tool may have run when its answer stops arriving, so the model does not call it again' do
        allow(connection).to receive(:call).and_raise(Captain::Mcp::Connection::DeadlineExceeded, 'too slow')

        expect(tool.perform(tool_context, status: 'open')).to eq(described_class::OUTCOME_UNKNOWN)
      end

      it 'reads as an error when the listing before the call fails' do
        allow(connection).to receive(:live_tool_definitions).and_raise(Captain::Mcp::Connection::DeadlineExceeded, 'too slow')

        expect(tool.perform(tool_context, status: 'open')).to eq('An error occurred while calling the tool')
      end
    end
  end

  describe 'a failure the server reports' do
    let(:base_class) { Captain::Tools::PublicMcpTool }

    it 'reads as an error, with the text the server sent' do
      allow(connection).to receive(:call).and_return(instance_double(RubyLLM::MCP::Result, text: 'Invoice not found', structured: nil, error?: true))

      result = tool.perform(Struct.new(:state).new(tool_context.state.merge(source: 'playground')), status: 'open')

      expect(result).to start_with('ERROR: The tool reported an error:')
      expect(result).to include('Invoice not found')
    end

    it 'reads as an error when the server sent no text' do
      allow(connection).to receive(:call).and_return(instance_double(RubyLLM::MCP::Result, text: nil, structured: nil, error?: true))

      expect(tool.perform(tool_context, status: 'open')).to eq('The tool reported an error')
    end
  end

  describe Captain::Tools::CopilotMcpTool do
    let(:base_class) { described_class }

    it 'is what a customer tool becomes when an admin or an agent is the user' do
      copilot_tool = Captain::Mcp::AgentTools.build(assistant, mcp_tool, connection, base_class: Captain::Tools::PublicMcpTool).for_copilot

      expect(copilot_tool).to be_a(described_class)
      expect(copilot_tool.parameters_schema['properties'].keys.map(&:to_s)).to contain_exactly('email', 'status')
    end

    it 'sends the email the model passed with the fixed value, and says when the email is not verified' do
      result = tool.perform(tool_context, email: 'typed@example.com', limit: '500')

      expect(connection).to have_received(:call).with('list_invoices', { email: 'typed@example.com', limit: '20' })
      expect(result).to include(Captain::ParamSources::UNVERIFIED_VALUE_NOTE)
    end

    it 'adds no note when the email is the one the customer verified' do
      expect(tool.perform(tool_context, email: 'Jane@Example.com')).not_to include(Captain::ParamSources::UNVERIFIED_VALUE_NOTE)
    end
  end

  describe 'a customer message that arrives while the server is listed' do
    let(:base_class) { Captain::Tools::PublicMcpTool }
    let(:stale_context) do
      responding_to = create(:message, conversation: conversation, account: account, message_type: :incoming)
      Struct.new(:state).new({ account_id: account.id, conversation: { id: conversation.id }, responding_to_message_id: responding_to.id })
    end

    before do
      allow(connection).to receive(:live_tool_definitions) do
        create(:message, conversation: conversation, account: account, message_type: :incoming, content: 'Stop, do not do that')
        [definition]
      end
    end

    context 'when the tool changes data' do
      let(:definition) { super().merge('read_only' => false) }

      it 'does not call the tool' do
        expect(tool.execute(stale_context, status: 'open')).to eq(Captain::Tools::BasePublicTool::NEWER_MESSAGE_ARRIVED)
        expect(connection).not_to have_received(:call)
      end
    end

    it 'still calls a tool that changes nothing' do
      tool.execute(stale_context, status: 'open')

      expect(connection).to have_received(:call)
    end
  end

  describe '#read_only?' do
    let(:base_class) { Captain::Tools::PublicMcpTool }

    it 'follows the approved definition' do
      expect(tool.read_only?).to be(true)
    end
  end

  it 'does not run for a tool class that does not decide its arguments' do
    tool = Captain::Mcp::AgentTools.build(assistant, mcp_tool, connection, base_class: described_class)

    expect { tool.perform(tool_context, status: 'open') }.to raise_error(NotImplementedError)
    expect(connection).not_to have_received(:call)
  end
end
