# frozen_string_literal: true

module Aws
  module Plugins

    class EventStreamConfiguration < Seahorse::Client::Plugin
      
      option(:event_stream_handler,
        default: nil,
        doc_type: 'Proc',
        docstring: <<-DOCS)
When an EventStream or Proc object is provided, it will be used as callback for each chunk of event stream response received along the way.
      DOCS

      option(:input_event_stream_handler,
        default: nil,
        doc_type: 'Proc',
        docstring: <<-DOCS)
When an EventStream or Proc object is provided, it can be used for sending events for the event stream.
      DOCS

      option(:output_event_stream_handler,
        default: nil,
        doc_type: 'Proc',
        docstring: <<-DOCS)
When an EventStream or Proc object is provided, it will be used as callback for each chunk of event stream response received along the way.
      DOCS

    end

  end
end
