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
  let(:mcp_tool) do
    definition = { 'name' => 'list_invoices', 'description' => 'List invoices', 'input_schema' => schema, 'read_only' => true }
    sources = { 'email' => { 'source' => 'verified.email' }, 'limit' => { 'source' => 'fixed', 'value' => '20' } }
    server.sync_tools({ 'list_invoices' => { 'param_sources' => sources } }, { 'list_invoices' => definition })
    server.tools.first
  end
  let(:ok_result) { instance_double(RubyLLM::MCP::Result, text: 'ok', structured: nil, error?: false) }
  let(:connection) { instance_double(Captain::Mcp::Connection, call: ok_result) }
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

    context 'when the customer has not verified an email' do
      let(:verified_email) { nil }

      it 'does not call the server and tells the model to verify the customer' do
        expect(tool.perform(tool_context, status: 'open')).to eq(Captain::ParamSources::UNVERIFIED)
        expect(connection).not_to have_received(:call)
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

    it 'shows the model the verified parameter but not the fixed one' do
      expect(tool.parameters_schema['properties'].keys.map(&:to_s)).to contain_exactly('email', 'status')
    end

    it 'sends the email the model passed with the fixed value, and says when the email is not verified' do
      result = tool.perform(tool_context, email: 'typed@example.com', limit: '500')

      expect(connection).to have_received(:call).with('list_invoices', { email: 'typed@example.com', limit: '20' })
      expect(result).to include(Captain::Tools::CopilotHttpTool::UNVERIFIED_VALUE_NOTE)
    end

    it 'adds no note when the email is the one the customer verified' do
      expect(tool.perform(tool_context, email: 'Jane@Example.com')).not_to include(Captain::Tools::CopilotHttpTool::UNVERIFIED_VALUE_NOTE)
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
