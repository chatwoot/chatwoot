class Captain::AssistantMigration::InstructionAuditor < Captain::BaseTaskService
  AUDITOR_MODEL = 'gpt-5.2'.freeze
  pattr_initialize [:assistant!, :source_payload!, :draft!, :available_additions!]

  def perform
    make_api_call(
      model: AUDITOR_MODEL,
      messages: messages,
      schema: Captain::AssistantMigration::InstructionAuditorSchema.for(available_additions)
    )
  end

  private

  def account
    assistant.account
  end

  def messages
    [
      { role: 'system', content: system_prompt },
      {
        role: 'user',
        content: JSON.pretty_generate(source: source_payload, generated_draft: draft, available_additions: available_additions)
      }
    ]
  end

  def system_prompt
    Captain::PromptRenderer.render('instruction_auditor')
  end

  def event_name
    'assistant_migration_instruction_auditor'
  end

  def captain_tasks_enabled?
    true
  end

  def counts_toward_usage?
    false
  end

  def build_follow_up_context?
    false
  end
end
