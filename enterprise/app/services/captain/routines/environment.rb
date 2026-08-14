class Captain::Routines::Environment
  class << self
    def prompt
      <<~PROMPT
        Captain Routines execute inside one Chatwoot account.

        Chatwoot's native workflow concepts are:
        - conversations belong to an inbox and contact;
        - conversations may independently have an assigned team and an assigned agent;
        - conversation statuses are open, resolved, pending, and snoozed;
        - conversation priorities are low, medium, high, and urgent;
        - labels and conversation custom attributes provide account-defined classification;
        - messages may be customer-visible replies or internal private notes;
        - inbox business hours are configured per inbox and evaluated in that inbox's timezone.

        Terms such as L1, L2, VIP, churn risk, incident, and customer segment are organization-specific rather than native
        Chatwoot fields. Resolve them from the administrator's wording or account records. If materially different mappings remain,
        record a clarification request instead of guessing.

        Named agents, teams, inboxes, and labels are account records. The planner grounds unique matches as pinned plan resources.
        An unresolved or ambiguous name requires administrator clarification; a record or ID must never be invented.

        The operation catalog is the complete executable vocabulary for this Routine version. A capability absent from the catalog
        is unsupported.
      PROMPT
    end
  end
end
