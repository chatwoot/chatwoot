require 'rails_helper'

# Test tool implementation
class TestTool < Captain::Tools::BaseService
  attr_accessor :tool_active

  def initialize(assistant, user: nil)
    super
    @tool_active = true
  end

  def name
    'test_tool'
  end

  def description
    'A test tool for specs'
  end

  def parameters
    {
      type: 'object',
      properties: {
        test_param: {
          type: 'string'
        }
      }
    }
  end

  def execute(*args)
    args
  end

  def active?
    @tool_active
  end
end

RSpec.describe Captain::ToolRegistryService do
  let(:assistant) { create(:captain_assistant) }
  let(:service) { described_class.new(assistant) }

  describe '#initialize' do
    it 'initializes with empty tools and registered_tools' do
      expect(service.tools).to be_empty
      expect(service.registered_tools).to be_empty
    end
  end

  describe '#register_tool' do
    let(:tool_class) { TestTool }

    context 'when tool is active' do
      it 'registers a new tool' do
        service.register_tool(tool_class)
        expect(service.tools['test_tool']).to be_a(TestTool)
        expect(service.registered_tools).to include(
          {
            type: 'function',
            function: {
              name: 'test_tool',
              description: 'A test tool for specs',
              parameters: {
                type: 'object',
                properties: {
                  test_param: {
                    type: 'string'
                  }
                }
              }
            }
          }
        )
      end
    end

    context 'when tool is inactive' do
      it 'does not register the tool' do
        tool = tool_class.new(assistant)
        tool.tool_active = false
        allow(tool_class).to receive(:new).and_return(tool)

        service.register_tool(tool_class)

        expect(service.tools['test_tool']).to be_nil
        expect(service.registered_tools).to be_empty
      end
    end
  end

  describe 'method_missing' do
    let(:tool_class) { TestTool }

    before do
      service.register_tool(tool_class)
    end

    context 'when method corresponds to a registered tool' do
      it 'executes the tool with given arguments' do
        result = service.test_tool(test_param: 'arg1')
        expect(result).to eq([{ test_param: 'arg1' }])
      end
    end

    context 'when method does not correspond to a registered tool' do
      it 'raises NoMethodError' do
        expect { service.unknown_tool }.to raise_error(NoMethodError)
      end
    end
  end

  describe '#tools_summary' do
    let(:tool_class) { TestTool }

    before do
      service.register_tool(tool_class)
    end

    it 'returns formatted summary of registered tools' do
      expect(service.tools_summary).to eq('- test_tool: A test tool for specs')
    end

    context 'when multiple tools are registered' do
      let(:another_tool_class) do
        Class.new(Captain::Tools::BaseService) do
          def name
            'another_tool'
          end

          def description
            'Another test tool'
          end

          def parameters
            {
              type: 'object',
              properties: {}
            }
          end

          def active?
            true
          end
        end
      end

      it 'includes all tools in the summary' do
        service.register_tool(another_tool_class)
        expect(service.tools_summary).to eq("- test_tool: A test tool for specs\n- another_tool: Another test tool")
      end
    end
  end
end
