# frozen_string_literal: true

# Unified attribution for messages and activity lines (automation, macro, flow).
module MessageSourceAttributes
  module_function

  def for_automation(rule)
    payload('automation', rule.id, rule.name).merge(
      automation_rule_id: rule.id,
      automation_rule_name: rule.name
    )
  end

  def for_macro(macro)
    payload('macro', macro.id, macro.name).merge(
      macro_id: macro.id,
      macro_name: macro.name
    )
  end

  def for_flow(run)
    payload('flow', run.flow_id, run.flow.name).merge(
      flow_run_id: run.id,
      flow_id: run.flow_id,
      flow_name: run.flow.name
    )
  end

  def payload(type, id, name)
    { message_source: { type: type, id: id, name: name } }
  end
end
