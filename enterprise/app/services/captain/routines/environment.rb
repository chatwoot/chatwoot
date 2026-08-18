class Captain::Routines::Environment
  DOMAIN_MODEL = <<~MODEL.freeze
    Type notation: `type?` is nullable, `type[]` is a collection, and `a | b` is a union.

    conversation:
      id: integer
      display_id: integer
      status: open | resolved | pending | snoozed
      priority: (low | medium | high | urgent)?
      created_at: timestamp
      last_activity_at: timestamp
      waiting_since: timestamp?
      snoozed_until: timestamp?
      labels: string[]
      custom_attributes: object
      additional_attributes: object
      contact: contact
      inbox: inbox
      assignee: agent?
      team: team?

    contact:
      id: integer
      name: string?
      email: string?
      phone_number: string?
      identifier: string?
      labels: string[]
      custom_attributes: object
      additional_attributes: object
      last_activity_at: timestamp?
      notes: contact_note[]?

    contact_note:
      id: integer
      content: string
      created_at: timestamp

    message:
      id: integer
      message_type: incoming | outgoing
      private: boolean
      content: string?
      sender: (agent | contact | external_sender)?
      created_at: timestamp

    agent:
      id: integer
      name: string
      email: string
      availability: online | offline | busy

    team:
      id: integer
      name: string

    inbox:
      id: integer
      name: string
      channel_type: string
      timezone: string

    label:
      id: integer
      title: string
      description: string?
      color: string?

    external_sender:
      id: integer
      name: string?
      type: string

    agent_workload:
      agent: agent
      open_conversations: integer
      by_priority: object
      by_inbox: object[]
      capacity_policy: capacity_policy?

    capacity_policy:
      id: integer
      name: string
      inbox_limits: object[]

    inbox_availability:
      working_hours_enabled: boolean
      status: unrestricted | within_business_hours | outside_business_hours
      timezone: string
      evaluated_at: timestamp
      local_time: timestamp
      schedule: business_hours_schedule?

    business_hours_schedule:
      day_of_week: integer
      closed_all_day: boolean
      open_all_day: boolean
      opens_at: timestamp?
      closes_at: timestamp?

    knowledge_result:
      one of help_center_article | captain_faq

    help_center_article:
      type: help_center_article
      id: integer
      title: string
      content: string
      locale: string
      url: string

    captain_faq:
      type: captain_faq
      id: integer
      question: string
      answer: string
      url: string?

    stripe_payment:
      id: string
      customer_email: string?
      status: succeeded
      amount_cents: integer
      currency: string
      billing_reason: subscription_cycle | duplicate
      created_at: timestamp
      refundable: boolean
      refunded: boolean
      refund_id: string?
      matched_by: object[]
      duplicate_of: string?
      trial: object?

    stripe_refund:
      id: string
      payment_id: string
      status: succeeded
      amount_cents: integer
      currency: string
      reason: duplicate_payment | accidental_trial_charge
      created_at: timestamp
  MODEL

  class << self
    def prompt
      <<~PROMPT
        Captain Routines execute inside one Chatwoot account.

        Chatwoot data available to Routine operations:
        #{DOMAIN_MODEL}

        Team and agent assignments are independent: either may be absent, and a team assignment never implies an individual
        assignee. Nullable values may be absent on selected records. The autonomous per-record Captain can inspect available
        context and decide how to handle ordinary missing data; do not require the administrator to define every absent-value case.

        Labels and custom attributes provide account-defined classification. Messages may be customer-visible replies or internal
        private notes. Inbox business hours are configured per inbox and evaluated in that inbox's timezone.

        The domain model and operation catalog define Chatwoot-native vocabulary. Treat terminology outside that vocabulary as the
        administrator's account or business nomenclature, regardless of how familiar it sounds. Requests may be informal,
        translated, misspelled, or grammatically incomplete; infer their intended meaning without treating language quality as
        ambiguity. Map account nomenclature to Chatwoot concepts only when the request or live account data makes the mapping
        unambiguous. If materially different mappings would change behavior, ask a concise clarification in the administrator's
        own terms instead of guessing or exposing implementation terminology.

        Named agents, teams, inboxes, and labels are account records. The builder grounds unique matches as pinned DSL resources.
        An unresolved or ambiguous name requires administrator clarification; a record or ID must never be invented.

        The operation catalog is the complete executable vocabulary for this Routine version. Each query declares the domain
        entity it returns. A capability absent from the catalog is unsupported.
      PROMPT
    end
  end
end
