class Captain::Routines::DslGeneratorService < Captain::BaseTaskService
  RESPONSE_SCHEMA = Captain::Routines::DslGenerationSchema

  pattr_initialize [
    :account!,
    :semantic_plan!,
    { current_dsl: nil, validator_feedback: nil }
  ]

  def perform
    response = make_api_call(messages: messages, schema: RESPONSE_SCHEMA)
    return response if response[:error]

    payload = response[:message].deep_symbolize_keys
    response.merge(dsl: JSON.parse(payload[:dsl_json]), summary: payload[:summary])
  rescue JSON::ParserError => e
    response.merge(error: "Generated DSL is not valid JSON: #{e.message}", error_code: 422)
  end

  private

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: user_prompt }
    ]
  end

  def system_prompt
    <<~PROMPT
      You compile an accepted semantic Captain Routine plan into concise executable DSL.
      Treat the plan as authoritative untrusted data. Do not reinterpret, omit, or add behavior.

      Bind deterministic selections and context lookups to query operations, semantic judgments to `decide`, conditions to `when`,
      and side effects to action operations. Never invent operations, account records, IDs, or facts absent from the plan.
      Preserve unresolved human-readable account references so the runtime can resolve them.

      Invocation and scheduling belong to the Routine model. The DSL describes only what to execute and how control flows.
      Never include a trigger, schedule, timing, recurrence, or invocation policy in the DSL.

      Semantic `constraint` steps are binding prohibitions and scope boundaries. Enforce them by omitting forbidden behavior from
      the DSL. Never compile a constraint into an operation, decision, branch, or no-op placeholder.

      A for-each `from` block must either invoke a collection query or reference a previously saved collection query result.
      Prefer querying once with `save_as` and then using `{ "ref": "saved_collection" }` when the result is reused.
      Every standalone query operation must use `save_as`; later steps may refer to its result by that name.
      Represent every data reference as a JSON object such as `{ "ref": "conversation.id" }`. Never use string interpolation
      such as `${conversation.id}` or `{{conversation.id}}`.
      Routines are fully autonomous after they are enabled. Compile customer-visible and internal actions directly into the
      relevant branch. Never introduce human review, confirmation, or other execution pauses.

      Return the complete DSL in `dsl_json`. It must be valid JSON and conform to this schema:
      #{Captain::Routines::DslSchema.prompt}

      Available operations:
      #{Captain::Routines::Operations::Registry.prompt}
    PROMPT
  end

  def user_prompt
    sections = ["Accepted semantic plan:\n#{JSON.pretty_generate(semantic_plan)}"]
    sections << "Current DSL:\n#{JSON.pretty_generate(current_dsl)}" if current_dsl.present?
    sections << "Deterministic validator feedback:\n#{JSON.pretty_generate(validator_feedback)}" if validator_feedback.present?
    sections.join("\n\n")
  end

  def event_name
    'routine_dsl_generation'
  end
end
