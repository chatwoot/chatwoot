# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Saas::AgentTool, type: :model do
  let(:account) { create(:account) }
  let(:ai_agent) { create(:ai_agent, account: account) }

  describe 'associations' do
    it { is_expected.to belong_to(:ai_agent).class_name('Saas::AiAgent') }
    it { is_expected.to belong_to(:account).class_name('::Account') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
  end

  describe '#url_template_not_obviously_internal' do
    context 'with valid external URLs' do
      it 'allows https URLs' do
        tool = build(:agent_tool, ai_agent: ai_agent, url_template: 'https://api.example.com/webhook')
        expect(tool).to be_valid
      end

      it 'allows URLs with Liquid variables' do
        tool = build(:agent_tool, ai_agent: ai_agent, url_template: 'https://api.example.com/{{conversation_id}}')
        expect(tool).to be_valid
      end
    end

    context 'with blocked internal URLs' do
      it 'rejects localhost' do
        tool = build(:agent_tool, ai_agent: ai_agent, url_template: 'http://localhost/admin')
        expect(tool).not_to be_valid
        expect(tool.errors[:url_template]).to include('must not point to internal or private addresses')
      end

      it 'rejects 127.0.0.1' do
        tool = build(:agent_tool, ai_agent: ai_agent, url_template: 'http://127.0.0.1/secret')
        expect(tool).not_to be_valid
      end

      it 'rejects 169.254.169.254 (cloud metadata)' do
        tool = build(:agent_tool, ai_agent: ai_agent, url_template: 'http://169.254.169.254/latest/meta-data/')
        expect(tool).not_to be_valid
      end

      it 'rejects metadata.google.internal' do
        tool = build(:agent_tool, ai_agent: ai_agent, url_template: 'http://metadata.google.internal/computeMetadata/v1/')
        expect(tool).not_to be_valid
      end

      it 'rejects .local domains' do
        tool = build(:agent_tool, ai_agent: ai_agent, url_template: 'http://myserver.local/api')
        expect(tool).not_to be_valid
      end
    end

    context 'with invalid schemes' do
      it 'rejects ftp URLs' do
        tool = build(:agent_tool, ai_agent: ai_agent, url_template: 'ftp://files.internal/data')
        expect(tool).not_to be_valid
        expect(tool.errors[:url_template]).to include('must use http or https')
      end
    end

    context 'with non-http tool types' do
      it 'skips URL validation for handoff tools' do
        tool = build(:agent_tool, :handoff, ai_agent: ai_agent)
        expect(tool).to be_valid
      end
    end
  end

  describe '#to_llm_tool' do
    it 'returns OpenAI function-calling format' do
      tool = build(:agent_tool, ai_agent: ai_agent, name: 'Get Weather', description: 'Gets the weather')
      result = tool.to_llm_tool

      expect(result[:type]).to eq('function')
      expect(result[:function][:name]).to eq('get_weather')
      expect(result[:function][:description]).to eq('Gets the weather')
    end
  end

  describe '#rendered_url' do
    it 'renders Liquid variables in URL template' do
      tool = build(:agent_tool, ai_agent: ai_agent, url_template: 'https://api.example.com/conversations/{{conversation_id}}')
      result = tool.rendered_url({ conversation_id: '42' })

      expect(result).to eq('https://api.example.com/conversations/42')
    end
  end

  describe '#rendered_body' do
    it 'renders Liquid variables in body template' do
      tool = build(:agent_tool, ai_agent: ai_agent, body_template: '{"id": "{{conversation_id}}"}')
      result = tool.rendered_body({ conversation_id: '42' })

      expect(result).to eq('{"id": "42"}')
    end

    it 'returns nil when body_template is blank' do
      tool = build(:agent_tool, ai_agent: ai_agent, body_template: nil)
      expect(tool.rendered_body({})).to be_nil
    end
  end
end
