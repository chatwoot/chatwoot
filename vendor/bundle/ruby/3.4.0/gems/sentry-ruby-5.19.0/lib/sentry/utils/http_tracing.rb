# frozen_string_literal: true

module Sentry
  module Utils
    module HttpTracing
      def set_span_info(sentry_span, request_info, response_status)
        sentry_span.set_description("#{request_info[:method]} #{request_info[:url]}")
        sentry_span.set_data(Span::DataConventions::URL, request_info[:url])
        sentry_span.set_data(Span::DataConventions::HTTP_METHOD, request_info[:method])
        sentry_span.set_data(Span::DataConventions::HTTP_QUERY, request_info[:query]) if request_info[:query]
        sentry_span.set_data(Span::DataConventions::HTTP_STATUS_CODE, response_status)
      end

      def set_propagation_headers(req)
        Sentry.get_trace_propagation_headers&.each { |k, v| req[k] = v }
      end

      def record_sentry_breadcrumb(request_info, response_status)
        crumb = Sentry::Breadcrumb.new(
          level: :info,
          category: self.class::BREADCRUMB_CATEGORY,
          type: :info,
          data: { status: response_status, **request_info }
        )

        Sentry.add_breadcrumb(crumb)
      end

      def record_sentry_breadcrumb?
        Sentry.initialized? && Sentry.configuration.breadcrumbs_logger.include?(:http_logger)
      end

      def propagate_trace?(url)
        url &&
          Sentry.initialized? &&
          Sentry.configuration.propagate_traces &&
          Sentry.configuration.trace_propagation_targets.any? { |target| url.match?(target) }
      end
    end
  end
end
