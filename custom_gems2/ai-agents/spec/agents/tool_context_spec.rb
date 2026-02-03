# frozen_string_literal: true

require_relative "../../lib/agents"

RSpec.describe Agents::ToolContext do
  let(:run_context) { instance_double(Agents::RunContext) }
  let(:context_hash) { { user_id: 123, session: "test" } }
  let(:usage_tracker) { instance_double(Agents::RunContext::Usage) }
  let(:tool_context) { described_class.new(run_context: run_context, retry_count: 2) }

  before do
    allow(run_context).to receive_messages(context: context_hash, usage: usage_tracker)
  end

  describe "#initialize" do
    it "stores the run_context" do
      expect(tool_context.run_context).to eq(run_context)
    end

    it "stores the retry_count" do
      expect(tool_context.retry_count).to eq(2)
    end

    it "defaults retry_count to 0 when not provided" do
      default_tool_context = described_class.new(run_context: run_context)
      expect(default_tool_context.retry_count).to eq(0)
    end
  end

  describe "#context" do
    it "delegates to run_context.context" do
      result = tool_context.context
      expect(result).to eq(context_hash)
      expect(run_context).to have_received(:context)
    end
  end

  describe "#usage" do
    it "delegates to run_context.usage" do
      result = tool_context.usage
      expect(result).to eq(usage_tracker)
      expect(run_context).to have_received(:usage)
    end
  end

  describe "#retry_count" do
    it "returns the retry_count" do
      expect(tool_context.retry_count).to eq(2)
    end
  end

  describe "#state" do
    context "when state exists in context" do
      let(:existing_state) { { customer_id: 456, customer_name: "John" } }
      let(:context_hash) { { user_id: 123, session: "test", state: existing_state } }

      it "returns the existing state hash" do
        result = tool_context.state
        expect(result).to eq(existing_state)
      end

      it "allows modifications to the state" do
        tool_context.state[:new_key] = "new_value"
        expect(tool_context.state[:new_key]).to eq("new_value")
      end
    end

    context "when state does not exist in context" do
      let(:context_hash) { { user_id: 123, session: "test" } }

      it "initializes state as empty hash" do
        result = tool_context.state
        expect(result).to eq({})
      end

      it "persists the initialized state in context" do
        tool_context.state
        expect(context_hash[:state]).to eq({})
      end

      it "allows adding to the initialized state" do
        tool_context.state[:customer_id] = 789
        expect(tool_context.state[:customer_id]).to eq(789)
        expect(context_hash[:state][:customer_id]).to eq(789)
      end
    end

    context "when state is nil in context" do
      let(:context_hash) { { user_id: 123, session: "test", state: nil } }

      it "replaces nil with empty hash" do
        result = tool_context.state
        expect(result).to eq({})
        expect(context_hash[:state]).to eq({})
      end
    end
  end
end
