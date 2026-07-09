# Reads the opt-in Meta funnel stage type configured on a pipeline stage.
#
# Stored (no migration) under crm_pipeline_stages.metadata['funnel_stage_type']; the
# admin sets it to a canonical CAPI-BM event name (e.g. 'LeadSubmitted',
# 'QualifiedLead', 'InitiateCheckout'). nil means "do not emit a CAPI event for
# movements into this stage".
module Crm::MetaCapi::StageTypeResolver
  module_function

  def resolve(stage)
    return if stage.blank?

    stage.metadata&.dig('funnel_stage_type').presence
  end
end
