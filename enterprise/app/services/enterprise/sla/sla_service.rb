class Enterprise::SlaService
  def perform
    # account.sla_policies.each do |sla_policy|
    #   sla_policy.sla_violations.each do |sla_violation|
    #     next if sla_violation.resolved?

    #     sla_violation.update!(resolved: true)
    #     sla_violation.sla_policy.sla_violations.create!(sla_violation_params(sla_violation))
    #   end
    # end
  end
end
