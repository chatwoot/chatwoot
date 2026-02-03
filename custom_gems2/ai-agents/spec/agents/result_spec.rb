# frozen_string_literal: true

require_relative "../../lib/agents"

RSpec.describe Agents::RunResult do
  describe "#success?" do
    it "returns true when no error and output exists" do
      result = described_class.new(output: "success", error: nil)
      expect(result.success?).to be true
    end

    it "returns false when error exists" do
      result = described_class.new(output: "success", error: StandardError.new("test error"))
      expect(result.success?).to be false
    end

    it "returns false when output is nil" do
      result = described_class.new(output: nil, error: nil)
      expect(result.success?).to be false
    end

    it "returns false when both error exists and output is nil" do
      result = described_class.new(output: nil, error: StandardError.new("test error"))
      expect(result.success?).to be false
    end
  end

  describe "#failed?" do
    it "returns false when successful" do
      result = described_class.new(output: "success", error: nil)
      expect(result.failed?).to be false
    end

    it "returns true when error exists" do
      result = described_class.new(output: "success", error: StandardError.new("test error"))
      expect(result.failed?).to be true
    end

    it "returns true when output is nil" do
      result = described_class.new(output: nil, error: nil)
      expect(result.failed?).to be true
    end
  end

  describe "initialization" do
    it "creates result with all fields" do
      usage = {}
      messages = [{ role: :user, content: "Hello" }]
      context = { user_id: 123 }
      error = StandardError.new("test")

      result = described_class.new(
        output: "Hello world",
        messages: messages,
        usage: usage,
        error: error,
        context: context
      )

      expect(result.output).to eq("Hello world")
      expect(result.messages).to eq(messages)
      expect(result.usage).to eq(usage)
      expect(result.error).to eq(error)
      expect(result.context).to eq(context)
    end

    it "accepts keyword arguments" do
      result = described_class.new(output: "test", error: nil)

      expect(result.output).to eq("test")
      expect(result.error).to be_nil
    end

    it "allows nil values for optional fields" do
      result = described_class.new(output: "test")

      expect(result.messages).to be_nil
      expect(result.usage).to be_nil
      expect(result.error).to be_nil
      expect(result.context).to be_nil
    end
  end
end
