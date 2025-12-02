require 'rails_helper'

RSpec.describe Captain::Tool do
  subject { described_class.new(name: 'test_tool', config: config) }

  let(:config) do
    {
      description: 'A test tool',
      properties: {
        'test_prop' => { 'type' => 'string', 'required' => true }
      },
      secrets: ['API_KEY'],
      implementation: proc { |input, _secrets, _memory| "Executed with #{input[:test_prop]}" }
    }
  end

  describe '#initialize' do
    it 'sets the attributes correctly' do
      expect(subject.name).to eq('test_tool')
      expect(subject.description).to eq('A test tool')
      expect(subject.properties).to eq(config[:properties])
      expect(subject.secrets).to eq(['API_KEY'])
    end
  end

  describe '#execute' do
    let(:input) { { test_prop: 'value' } }
    let(:secrets) { { API_KEY: 'secret' } }

    it 'executes the implementation block' do
      expect(subject.execute(input, secrets)).to eq('Executed with value')
    end

    context 'when secrets are missing' do
      it 'raises ExecutionError with missing secrets message' do
        expect { subject.execute(input, {}) }.to raise_error(Captain::Tool::ExecutionError, /Missing required secrets: API_KEY/)
      end
    end

    context 'when input is invalid' do
      it 'raises ExecutionError with missing property message' do
        expect { subject.execute({}, secrets) }.to raise_error(Captain::Tool::ExecutionError, /Missing required property: test_prop/)
      end
    end

    context 'when implementation is missing' do
      let(:config) { super().merge(implementation: nil) }

      it 'raises ExecutionError' do
        expect { subject.execute(input, secrets) }.to raise_error(Captain::Tool::ExecutionError)
      end
    end
  end
end
