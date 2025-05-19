require 'rails_helper'

# Test tool implementation
class TestTool < Captain::Tools::BaseService
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
end
