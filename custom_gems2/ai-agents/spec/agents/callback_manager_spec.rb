# frozen_string_literal: true

require_relative "../../lib/agents"

RSpec.describe Agents::CallbackManager do
  describe "#initialize" do
    it "stores empty callbacks when none provided" do
      manager = described_class.new
      expect(manager.instance_variable_get(:@callbacks)).to eq({})
    end

    it "stores provided callbacks" do
      callbacks = { tool_start: [proc { "test" }] }
      manager = described_class.new(callbacks)
      expect(manager.instance_variable_get(:@callbacks)).to eq(callbacks)
    end

    it "duplicates and freezes callbacks for thread safety" do
      callbacks = { tool_start: [] }
      manager = described_class.new(callbacks)
      stored_callbacks = manager.instance_variable_get(:@callbacks)

      expect(stored_callbacks).to be_frozen
      expect(stored_callbacks).not_to be(callbacks)
    end
  end

  describe "#emit" do
    it "calls all callbacks for the event type" do
      callback1 = instance_double(Proc)
      callback2 = instance_double(Proc)
      callbacks = { tool_start: [callback1, callback2] }
      manager = described_class.new(callbacks)

      allow(callback1).to receive(:call)
      allow(callback2).to receive(:call)

      manager.emit(:tool_start, "tool_name", { arg: "value" })

      expect(callback1).to have_received(:call).with("tool_name", { arg: "value" })
      expect(callback2).to have_received(:call).with("tool_name", { arg: "value" })
    end

    it "does nothing when no callbacks registered for event" do
      manager = described_class.new
      expect { manager.emit(:tool_start, "tool_name") }.not_to raise_error
    end

    it "handles callback errors gracefully" do
      failing_callback = proc { raise StandardError, "Callback error" }
      callbacks = { tool_start: [failing_callback] }
      manager = described_class.new(callbacks)

      expect { manager.emit(:tool_start, "tool_name") }.to output(/Callback error for tool_start/).to_stderr
    end

    it "continues executing remaining callbacks after one fails" do
      failing_callback = proc { raise StandardError, "Callback error" }
      success_callback = instance_double(Proc)
      callbacks = { tool_start: [failing_callback, success_callback] }
      manager = described_class.new(callbacks)

      allow(success_callback).to receive(:call)

      expect { manager.emit(:tool_start, "tool_name") }.to output(/Callback error/).to_stderr
      expect(success_callback).to have_received(:call).with("tool_name")
    end
  end

  describe "typed emit methods" do
    let(:callback) { instance_double(Proc) }
    let(:manager) do
      described_class.new(
        run_start: [callback],
        run_complete: [callback],
        agent_complete: [callback],
        tool_start: [callback],
        tool_complete: [callback],
        agent_thinking: [callback],
        agent_handoff: [callback]
      )
    end

    before do
      allow(callback).to receive(:call)
    end

    it "has emit_run_start method" do
      manager.emit_run_start("agent_name", "input", "context")
      expect(callback).to have_received(:call).with("agent_name", "input", "context")
    end

    it "has emit_run_complete method" do
      manager.emit_run_complete("agent_name", "result", "context")
      expect(callback).to have_received(:call).with("agent_name", "result", "context")
    end

    it "has emit_agent_complete method" do
      manager.emit_agent_complete("agent_name", "result", "error", "context")
      expect(callback).to have_received(:call).with("agent_name", "result", "error", "context")
    end

    it "has emit_tool_start method" do
      manager.emit_tool_start("tool_name", { key: "value" })
      expect(callback).to have_received(:call).with("tool_name", { key: "value" })
    end

    it "has emit_tool_complete method" do
      manager.emit_tool_complete("tool_name", "result")
      expect(callback).to have_received(:call).with("tool_name", "result")
    end

    it "has emit_agent_thinking method" do
      manager.emit_agent_thinking("agent_name", "input")
      expect(callback).to have_received(:call).with("agent_name", "input")
    end

    it "has emit_agent_handoff method" do
      manager.emit_agent_handoff("from_agent", "to_agent", "reason")
      expect(callback).to have_received(:call).with("from_agent", "to_agent", "reason")
    end
  end

  describe "thread safety" do
    it "can be safely used from multiple threads" do
      shared_data = []
      callback = proc { |data| shared_data << data }
      manager = described_class.new(tool_start: [callback])

      threads = 5.times.map do |i|
        Thread.new do
          manager.emit_tool_start("tool_#{i}")
        end
      end

      threads.each(&:join)

      expect(shared_data.length).to eq(5)
      expect(shared_data).to include("tool_0", "tool_1", "tool_2", "tool_3", "tool_4")
    end
  end
end
