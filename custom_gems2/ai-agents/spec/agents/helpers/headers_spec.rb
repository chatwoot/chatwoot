# frozen_string_literal: true

require "spec_helper"

RSpec.describe Agents::Helpers::Headers do
  describe ".normalize" do
    context "with nil input" do
      it "returns empty hash" do
        expect(described_class.normalize(nil)).to eq({})
      end

      it "returns frozen empty hash when freeze_result is true" do
        result = described_class.normalize(nil, freeze_result: true)

        expect(result).to eq({})
        expect(result).to be_frozen
      end
    end

    context "with empty hash" do
      it "returns empty hash" do
        expect(described_class.normalize({})).to eq({})
      end

      it "returns frozen empty hash when freeze_result is true" do
        result = described_class.normalize({}, freeze_result: true)

        expect(result).to eq({})
        expect(result).to be_frozen
      end
    end

    context "with string keys" do
      it "symbolizes keys" do
        headers = { "Content-Type" => "application/json", "X-Custom" => "value" }
        result = described_class.normalize(headers)

        expect(result).to eq({ "Content-Type": "application/json", "X-Custom": "value" })
      end

      it "returns a new hash object" do
        headers = { "X-Test" => "value" }
        result = described_class.normalize(headers)

        expect(result).not_to be(headers)
      end
    end

    context "with symbol keys" do
      it "preserves symbol keys" do
        headers = { "Content-Type": "application/json", "X-Custom": "value" }
        result = described_class.normalize(headers)

        expect(result).to eq({ "Content-Type": "application/json", "X-Custom": "value" })
      end
    end

    context "with mixed keys" do
      it "symbolizes all keys" do
        headers = { "X-String": "value1", "X-Symbol" => "value2" }
        result = described_class.normalize(headers)

        expect(result).to eq({ "X-String": "value1", "X-Symbol": "value2" })
      end
    end

    context "with freeze_result option" do
      it "freezes the result when true" do
        headers = { "X-Test" => "value" }
        result = described_class.normalize(headers, freeze_result: true)

        expect(result).to be_frozen
      end

      it "does not freeze when false" do
        headers = { "X-Test" => "value" }
        result = described_class.normalize(headers, freeze_result: false)

        expect(result).not_to be_frozen
      end

      it "does not freeze by default" do
        headers = { "X-Test" => "value" }
        result = described_class.normalize(headers)

        expect(result).not_to be_frozen
      end
    end

    context "with objects responding to to_h" do
      it "converts to hash and symbolizes keys" do
        obj = double("headers_object", to_h: { "X-Custom" => "value" }, empty?: false)
        result = described_class.normalize(obj)

        expect(result).to eq({ "X-Custom": "value" })
      end
    end

    context "with invalid input" do
      it "raises ArgumentError for objects not responding to to_h" do
        expect do
          described_class.normalize("invalid")
        end.to raise_error(ArgumentError, "headers must be a Hash or respond to #to_h")
      end

      it "raises TypeError for arrays without valid pairs" do
        expect do
          described_class.normalize([1, 2, 3])
        end.to raise_error(TypeError)
      end
    end
  end

  describe ".merge" do
    context "when both headers are empty" do
      it "returns empty hash" do
        result = described_class.merge({}, {})

        expect(result).to eq({})
      end
    end

    context "when agent_headers is empty" do
      it "returns runtime_headers" do
        runtime_headers = { "X-Runtime": "value" }
        result = described_class.merge({}, runtime_headers)

        expect(result).to eq(runtime_headers)
      end
    end

    context "when runtime_headers is empty" do
      it "returns agent_headers" do
        agent_headers = { "X-Agent": "value" }
        result = described_class.merge(agent_headers, {})

        expect(result).to eq(agent_headers)
      end
    end

    context "when both have different keys" do
      it "merges both hashes" do
        agent_headers = { "X-Agent": "agent-value" }
        runtime_headers = { "X-Runtime": "runtime-value" }
        result = described_class.merge(agent_headers, runtime_headers)

        expect(result).to eq({
                               "X-Agent": "agent-value",
                               "X-Runtime": "runtime-value"
                             })
      end
    end

    context "when both have overlapping keys" do
      it "gives precedence to runtime_headers" do
        agent_headers = { "X-Shared": "agent-value", "X-Agent-Only": "agent" }
        runtime_headers = { "X-Shared": "runtime-value", "X-Runtime-Only": "runtime" }
        result = described_class.merge(agent_headers, runtime_headers)

        expect(result).to eq({
                               "X-Shared": "runtime-value",
                               "X-Agent-Only": "agent",
                               "X-Runtime-Only": "runtime"
                             })
      end
    end

    context "when keys have same name but different values" do
      it "runtime value overwrites agent value" do
        agent_headers = { Authorization: "Bearer agent-token" }
        runtime_headers = { Authorization: "Bearer runtime-token" }
        result = described_class.merge(agent_headers, runtime_headers)

        expect(result).to eq({ Authorization: "Bearer runtime-token" })
      end
    end
  end
end
