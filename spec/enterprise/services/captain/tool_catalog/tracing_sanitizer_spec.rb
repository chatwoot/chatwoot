require 'rails_helper'

RSpec.describe Captain::ToolCatalog::TracingSanitizer do
  let(:callback_class) do
    klass = Class.new do
      attr_reader :events

      def initialize
        @events = []
      end

      def on_tool_start(tool_name, args, context_wrapper)
        events << [:start, tool_name, args, context_wrapper]
      end

      def on_tool_complete(tool_name, result, context_wrapper)
        events << [:complete, tool_name, result, context_wrapper]
      end
    end
    klass.prepend(described_class)
    klass
  end
  let(:context_wrapper) do
    OpenStruct.new(context: { state: { captain_catalog_tool_names: ['stripe_get_customer'] } })
  end

  it 'redacts catalog tool input and output before tracing callbacks receive them' do
    callbacks = callback_class.new

    callbacks.on_tool_start('stripe_get_customer', { email: 'customer@example.com' }, context_wrapper)
    callbacks.on_tool_complete('stripe_get_customer', { client_secret: 'secret' }, context_wrapper)

    expect(callbacks.events.map(&:third)).to eq([{ redacted: true }, { redacted: true }])
    expect(context_wrapper.context).not_to have_key(described_class::TRACE_TOOL_KEY)
  end

  it 'leaves existing tool tracing unchanged for non-catalog tools' do
    callbacks = callback_class.new

    callbacks.on_tool_start('faq_lookup', { query: 'refunds' }, context_wrapper)
    callbacks.on_tool_complete('faq_lookup', 'result', context_wrapper)

    expect(callbacks.events.map(&:third)).to eq([{ query: 'refunds' }, 'result'])
  end
end
