# frozen_string_literal: true

module Aws
  module Plugins
    # @api private
    class EndpointPattern < Seahorse::Client::Plugin

      option(:disable_host_prefix_injection,
        default: false,
        doc_type: 'Boolean',
        docstring: <<-DOCS
Set to true to disable SDK automatically adding host prefix
to default service endpoint when available.
        DOCS
      )

      def add_handlers(handlers, config)
        handlers.add(Handler, priority: 10)
      end

      class Handler < Seahorse::Client::Handler

        def call(context)
          if !context.config.disable_host_prefix_injection
            endpoint_trait = context.operation.endpoint_pattern
            if endpoint_trait && !endpoint_trait.empty?
              _apply_endpoint_trait(context, endpoint_trait)
            end
          end
          @handler.call(context)
        end

        private

        def _apply_endpoint_trait(context, trait)
          # currently only support host pattern
          ori_host = context.http_request.endpoint.host
          if pattern = trait['hostPrefix']
            host_prefix = pattern.gsub(/\{.+?\}/) do |label|
              label = label.delete("{}")
              _replace_label_value(
                ori_host, label, context.operation.input, context.params)
            end
            context.http_request.endpoint.host = host_prefix + context.http_request.endpoint.host
          end
        end

        def _replace_label_value(ori, label, input_ref, params)
          name = nil
          input_ref.shape.members.each do |m_name, ref|
            if ref['hostLabel'] && ref['hostLabelName'] == label
              name = m_name
            end
          end
          if name.nil? || params[name].nil?
            raise Errors::MissingEndpointHostLabelValue.new(name)
          end
          params[name]
        end

      end

    end
  end
end
