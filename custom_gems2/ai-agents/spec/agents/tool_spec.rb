# frozen_string_literal: true

require_relative "../../lib/agents"

RSpec.describe Agents::Tool do
  let(:tool_context) { instance_double(Agents::ToolContext, "ToolContext") }

  # Create test tool class for testing
  let(:test_tool_class) do
    Class.new(described_class) do
      def perform(tool_context, name:, age: nil, active: true)
        "Hello #{name}, age: #{age}, active: #{active}, context: #{tool_context}"
      end
    end
  end

  let(:test_tool) { test_tool_class.new }

  describe "#execute" do
    it "calls perform with tool_context and parameters" do
      result = test_tool.execute(tool_context, name: "John", age: 30, active: true)

      expect(result).to eq("Hello John, age: 30, active: true, context: #{tool_context}")
    end

    it "passes through optional parameters" do
      result = test_tool.execute(tool_context, name: "Jane")

      expect(result).to eq("Hello Jane, age: , active: true, context: #{tool_context}")
    end
  end

  describe "#perform" do
    it "must be implemented by subclasses" do
      tool_class = Class.new(described_class)
      tool = tool_class.new

      expect { tool.perform(tool_context) }.to raise_error(NotImplementedError)
    end

    it "receives tool_context as first parameter" do
      tool = test_tool_class.new
      result = tool.perform(tool_context, name: "Test")

      expect(result).to include("context: #{tool_context}")
    end
  end

  describe "class-based tool definition" do
    let(:class_based_tool_class) do
      Class.new(described_class) do
        description "A class-based test tool"

        def perform(tool_context, message:)
          "Processed: #{message} with context: #{tool_context}"
        end
      end
    end

    let(:class_based_tool) { class_based_tool_class.new }

    it "inherits description from class definition" do
      expect(class_based_tool.description).to eq("A class-based test tool")
    end

    it "executes perform method correctly" do
      result = class_based_tool.perform(tool_context, message: "hello")

      expect(result).to eq("Processed: hello with context: #{tool_context}")
    end
  end

  describe "inheritance from RubyLLM::Tool" do
    it "extends RubyLLM::Tool" do
      expect(described_class).to be < RubyLLM::Tool
    end

    it "maintains RubyLLM tool interface" do
      expect(test_tool).to respond_to(:name)
      expect(test_tool).to respond_to(:description)
    end
  end

  describe "RubyLLM tool interface" do
    context "when using parameter definition" do
      it "works with RubyLLM param syntax" do
        tool_class = Class.new(described_class) do
          param :name, type: "string", desc: "User's name"

          def perform(_tool_context, name:)
            "Hello #{name}"
          end
        end

        tool = tool_class.new
        expect(tool).to respond_to(:perform)
        result = tool.perform(tool_context, name: "John")
        expect(result).to eq("Hello John")
      end

      it "supports different parameter types" do
        tool_class = Class.new(described_class) do
          param :text, type: "string", desc: "Text input"
          param :count, type: "integer", desc: "Count value"
          param :amount, type: "number", desc: "Amount value"

          def perform(_tool_context, text:, count:, amount:)
            "Text: #{text}, Count: #{count}, Amount: #{amount}"
          end
        end

        tool = tool_class.new
        result = tool.perform(
          tool_context,
          text: "hello",
          count: 5,
          amount: 10.5
        )
        expect(result).to eq("Text: hello, Count: 5, Amount: 10.5")
      end

      it "supports optional parameters" do
        tool_class = Class.new(described_class) do
          param :required_param, type: "string", desc: "Required parameter"
          param :optional_param, type: "string", desc: "Optional parameter", required: false

          def perform(_tool_context, required_param:, optional_param: "default")
            "Required: #{required_param}, Optional: #{optional_param}"
          end
        end

        tool = tool_class.new
        result = tool.perform(tool_context, required_param: "test")
        expect(result).to eq("Required: test, Optional: default")
      end
    end
  end
end
