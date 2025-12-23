# frozen_string_literal: true

module Datadog
  module AppSec
    module Metrics
      # A class responsible for reporting WAF and RASP telemetry metrics.
      module Telemetry
        module_function

        def report_rasp(type, result)
          return if result.is_a?(SecurityEngine::Result::Error)

          tags = {rule_type: type, waf_version: Datadog::AppSec::WAF::VERSION::BASE_STRING}
          namespace = Ext::TELEMETRY_METRICS_NAMESPACE

          AppSec.telemetry.inc(namespace, 'rasp.rule.eval', 1, tags: tags)
          AppSec.telemetry.inc(namespace, 'rasp.rule.match', 1, tags: tags) if result.match?
          AppSec.telemetry.inc(namespace, 'rasp.timeout', 1, tags: tags) if result.timeout?
        end
      end
    end
  end
end
