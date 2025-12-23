# frozen_string_literal: true

module Datadog
  module AppSec
    module Ext
      RASP_SQLI = 'sql_injection'
      RASP_LFI = 'lfi'
      RASP_SSRF = 'ssrf'

      PRODUCT_BIT = 0b00000010

      INTERRUPT = :datadog_appsec_interrupt
      CONTEXT_KEY = 'datadog.appsec.context'
      ACTIVE_CONTEXT_KEY = :datadog_appsec_active_context
      EXPLOIT_PREVENTION_EVENT_CATEGORY = 'exploit'

      TAG_APPSEC_ENABLED = '_dd.appsec.enabled'
      TAG_METASTRUCT_STACK_TRACE = '_dd.stack'

      TELEMETRY_METRICS_NAMESPACE = 'appsec'
    end
  end
end
