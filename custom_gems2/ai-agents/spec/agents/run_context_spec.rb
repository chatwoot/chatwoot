# frozen_string_literal: true

require_relative "../../lib/agents"

RSpec.describe Agents::RunContext do
  let(:context_data) { { user_id: 123, session: "test_session" } }
  let(:run_context) { described_class.new(context_data) }

  describe "#initialize" do
    it "stores the provided context data" do
      expect(run_context.context).to eq(context_data)
    end

    it "initializes a new Usage tracker" do
      expect(run_context.usage).to be_a(Agents::RunContext::Usage)
    end

    it "accepts empty context" do
      empty_context = described_class.new({})
      expect(empty_context.context).to eq({})
    end
  end

  describe "#context" do
    it "provides access to the context data" do
      expect(run_context.context[:user_id]).to eq(123)
      expect(run_context.context[:session]).to eq("test_session")
    end

    it "allows context modification" do
      run_context.context[:new_key] = "new_value"
      expect(run_context.context[:new_key]).to eq("new_value")
    end
  end

  describe "#usage" do
    it "returns the Usage instance" do
      expect(run_context.usage).to be_an_instance_of(Agents::RunContext::Usage)
    end

    it "maintains the same Usage instance across calls" do
      usage1 = run_context.usage
      usage2 = run_context.usage
      expect(usage1).to be(usage2)
    end
  end

  describe "context isolation" do
    let(:base_context) { { shared_key: "shared_value" } }

    it "does not modify original context when context is changed" do
      original_value = base_context[:shared_key]
      context_copy = base_context.dup
      run_context = described_class.new(context_copy)

      run_context.context[:shared_key] = "modified_value"

      expect(base_context[:shared_key]).to eq(original_value)
    end

    it "allows independent context modifications across instances" do
      run_context1 = described_class.new(base_context.dup)
      run_context2 = described_class.new(base_context.dup)

      run_context1.context[:instance_id] = 1
      run_context2.context[:instance_id] = 2

      expect(run_context1.context[:instance_id]).to eq(1)
      expect(run_context2.context[:instance_id]).to eq(2)
    end
  end
end

RSpec.describe Agents::RunContext::Usage do
  let(:usage) { described_class.new }
  let(:usage_struct) { Struct.new(:input_tokens, :output_tokens, :total_tokens) }

  describe "#initialize" do
    it "initializes all token counters to zero" do
      expect(usage.input_tokens).to eq(0)
      expect(usage.output_tokens).to eq(0)
      expect(usage.total_tokens).to eq(0)
    end
  end

  describe "#add" do
    context "with valid usage object" do
      let(:llm_usage) { usage_struct.new(100, 50, 150) }

      it "adds input tokens to running total" do
        usage.add(llm_usage)
        expect(usage.input_tokens).to eq(100)
      end

      it "adds output tokens to running total" do
        usage.add(llm_usage)
        expect(usage.output_tokens).to eq(50)
      end

      it "adds total tokens to running total" do
        usage.add(llm_usage)
        expect(usage.total_tokens).to eq(150)
      end

      it "accumulates usage across multiple calls" do
        usage.add(llm_usage)
        usage.add(llm_usage)

        expect(usage.input_tokens).to eq(200)
        expect(usage.output_tokens).to eq(100)
        expect(usage.total_tokens).to eq(300)
      end
    end

    context "with nil values" do
      it "handles nil values gracefully" do
        nil_usage = usage_struct.new(nil, nil, nil)

        expect { usage.add(nil_usage) }.not_to raise_error
        expect(usage.input_tokens).to eq(0)
        expect(usage.output_tokens).to eq(0)
        expect(usage.total_tokens).to eq(0)
      end

      it "handles partial nil values" do
        partial_usage = usage_struct.new(50, nil, nil)

        usage.add(partial_usage)
        expect(usage.input_tokens).to eq(50)
        expect(usage.output_tokens).to eq(0)
        expect(usage.total_tokens).to eq(50)
      end
    end
  end

  describe "token counter modification" do
    it "allows direct modification of token counters" do
      usage.input_tokens = 500
      usage.output_tokens = 250
      usage.total_tokens = 750

      expect(usage.input_tokens).to eq(500)
      expect(usage.output_tokens).to eq(250)
      expect(usage.total_tokens).to eq(750)
    end
  end
end
