# frozen_string_literal: true

require_relative '../../../../tracing'
require_relative '../../../metadata/ext'
require_relative '../../analytics'
require_relative '../ext'
require_relative '../event'

module Datadog
  module Tracing
    module Contrib
      module ActionView
        module Events
          # Defines instrumentation for render_template.action_view event
          module RenderTemplate
            include ActionView::Event

            EVENT_NAME = 'render_template.action_view'

            module_function

            def event_name
              self::EVENT_NAME
            end

            def span_name
              Ext::SPAN_RENDER_TEMPLATE
            end

            def on_start(span, _event, _id, payload)
              span.service = configuration[:service_name] if configuration[:service_name]
              span.type = Tracing::Metadata::Ext::HTTP::TYPE_TEMPLATE

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_RENDER_TEMPLATE)

              if (template_name = Utils.normalize_template_name(payload[:identifier]))
                span.resource = template_name
                span.set_tag(Ext::TAG_TEMPLATE_NAME, template_name)
              end

              layout = payload[:layout]
              span.set_tag(Ext::TAG_LAYOUT, layout) if layout

              # Measure service stats
              Contrib::Analytics.set_measured(span)

              record_exception(span, payload)
            rescue StandardError => e
              Datadog.logger.debug(e.message)
            end
          end
        end
      end
    end
  end
end
