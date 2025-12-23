# frozen_string_literal: true

module Datadog
  module AppSec
    module Metrics
      # A class responsible for exporting WAF and RASP call metrics.
      module Exporter
        module_function

        def export_waf_metrics(metrics, span)
          return if metrics.evals.zero?

          span.set_tag('_dd.appsec.waf.timeouts', metrics.timeouts)
          span.set_tag('_dd.appsec.waf.duration', convert_ns_to_us(metrics.duration_ns))
          span.set_tag('_dd.appsec.waf.duration_ext', convert_ns_to_us(metrics.duration_ext_ns))
        end

        def export_rasp_metrics(metrics, span)
          return if metrics.evals.zero?

          span.set_tag('_dd.appsec.rasp.rule.eval', metrics.evals)
          span.set_tag('_dd.appsec.rasp.timeout', 1) unless metrics.timeouts.zero?
          span.set_tag('_dd.appsec.rasp.duration', convert_ns_to_us(metrics.duration_ns))
          span.set_tag('_dd.appsec.rasp.duration_ext', convert_ns_to_us(metrics.duration_ext_ns))
        end

        # private

        def convert_ns_to_us(value)
          value / 1000.0
        end
      end
    end
  end
end
