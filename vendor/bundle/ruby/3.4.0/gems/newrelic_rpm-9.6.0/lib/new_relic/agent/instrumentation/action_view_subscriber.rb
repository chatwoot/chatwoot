# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/notifications_subscriber'

# Listen for ActiveSupport::Notifications events for ActionView render
# events.  Write metric data and transaction trace nodes for each event.
module NewRelic
  module Agent
    module Instrumentation
      class ActionViewSubscriber < NotificationsSubscriber
        def start_segment(name, id, payload)
          parent = segment_stack[id].last
          metric_name = format_metric_name(name, payload, parent)

          event = ActionViewEvent.new(metric_name, payload[:identifier])

          if recordable?(name, metric_name)
            event.finishable = Tracer.start_segment(name: metric_name)
          end
          push_segment(id, event)
        end

        def finish_segment(id, payload)
          if segment = pop_segment(id)
            if exception = exception_object(payload)
              segment.notice_error(exception)
            end
            segment.finish
          end
        end

        def format_metric_name(event_name, payload, parent)
          return parent.name if parent \
             && (payload[:virtual_path] \
              || (parent.identifier =~ /template$/))

          if payload.key?(:virtual_path)
            identifier = payload[:virtual_path]
          else
            identifier = payload[:identifier]
          end

          "View/#{metric_path(event_name, identifier)}/#{metric_action(event_name)}"
        end

        # Nearly every "render_blah.action_view" event has a child
        # in the form of "!render_blah.action_view".  The children
        # are the ones we want to record.  There are a couple
        # special cases of events without children.
        def recordable?(event_name, metric_name)
          event_name[0] == '!' \
              || metric_name == 'View/text template/Rendering' \
              || metric_name == "View/#{::NewRelic::Agent::UNKNOWN_METRIC}/Partial"
        end

        RENDER_TEMPLATE_EVENT_NAME = 'render_template.action_view'.freeze
        RENDER_PARTIAL_EVENT_NAME = 'render_partial.action_view'.freeze
        RENDER_COLLECTION_EVENT_NAME = 'render_collection.action_view'.freeze
        RENDER_LAYOUT_EVENT_NAME = 'render_layout.action_view'.freeze

        def metric_action(name)
          case name
          when /#{RENDER_TEMPLATE_EVENT_NAME}$/o then 'Rendering'
          when RENDER_PARTIAL_EVENT_NAME then 'Partial'
          when RENDER_COLLECTION_EVENT_NAME then 'Partial'
          when RENDER_LAYOUT_EVENT_NAME then 'Layout'
          else NewRelic::UNKNOWN
          end
        end

        def metric_path(name, identifier)
          # Rails 5 sets identifier to nil for empty collections,
          # so do not mistake rendering a collection for rendering a file.
          if identifier.nil? && name != RENDER_COLLECTION_EVENT_NAME
            'file'
          elsif /template$/.match?(identifier)
            identifier
          elsif identifier && (parts = identifier.split('/')).size > 1
            parts[-2..-1].join('/')
          else
            ::NewRelic::Agent::UNKNOWN_METRIC
          end
        end
      end

      # This class holds state information between calls to `start`
      # and `finish` for ActiveSupport events that we do not want to track
      # as a transaction or segment.
      class ActionViewEvent
        attr_reader :name, :identifier
        attr_accessor :finishable

        def initialize(name, identifier)
          @name = name
          @identifier = identifier
          @finishable = nil
        end

        def finish
          @finishable&.finish
        end

        def notice_error(error)
          @finishable&.notice_error(error)
        end
      end
    end
  end
end
