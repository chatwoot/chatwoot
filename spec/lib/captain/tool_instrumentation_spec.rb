require 'rails_helper'

RSpec.describe Captain::ToolInstrumentation do
  subject(:instrumented) { Class.new { include Captain::ToolInstrumentation }.new }

  describe '#tool_session_output' do
    it 'keeps a text reply as it is' do
      expect(instrumented.send(:tool_session_output, { message: 'Hello' })).to eq('Hello')
    end

    it 'turns a structured reply into JSON' do
      output = instrumented.send(:tool_session_output, { message: { 'reply' => 'Hello', 'reply_needed' => true } })

      expect(JSON.parse(output)).to eq('reply' => 'Hello', 'reply_needed' => true)
    end

    it 'falls back to the whole response when there is no reply' do
      expect(instrumented.send(:tool_session_output, { error: 'failed' })).to eq({ error: 'failed' }.to_json)
    end
  end
end
