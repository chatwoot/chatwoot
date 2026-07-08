class Crm::StageAutomations::StepExecutor
  Result = Struct.new(:status, :payload, :error, keyword_init: true) do
    def self.ok(payload = {})
      new(status: :ok, payload: payload)
    end

    def self.failed(error)
      new(status: :failed, error: error)
    end
  end

  MAX_AUTOMATION_DEPTH = 3

  def initialize(card:, step:, actor:, automation_context: {})
    @card = card
    @step = step
    @actor = actor
    @automation_context = automation_context.to_h.with_indifferent_access
  end

  def perform
    case @step.action_type
    when 'create_follow_up'
      create_follow_up!
    when 'assign_owner'
      assign_owner!
    when 'move_stage'
      move_stage!
    else
      Result.failed('unsupported_action_type')
    end
  rescue StandardError => e
    Result.failed(e.message)
  end

  private

  def config
    (@step.action_config || {}).to_h.stringify_keys
  end

  def create_follow_up!
    conversation = @card.primary_conversation
    due_at = Time.current + @step.delay_seconds.seconds
    attributes = {
      title: config['title'].to_s.strip,
      description: config['description'].to_s,
      follow_up_type: config['follow_up_type'].presence || 'task',
      automation_mode: config['automation_mode'].presence || 'reminder_only',
      due_at: due_at,
      timezone: config['timezone'],
      metadata: build_follow_up_metadata
    }

    resolved = Crm::FollowUps::ParamsResolver.new(
      account: @card.account,
      user: @actor,
      card: @card,
      conversation: conversation,
      attributes: attributes
    ).perform

    follow_up = @card.account.crm_follow_ups.create!(
      resolved.merge(
        card: @card,
        created_by: @actor,
        metadata: resolved[:metadata].merge(
          'stage_automation_id' => @step.stage_automation_id,
          'stage_automation_step_id' => @step.id,
          'source' => 'stage_automation'
        )
      )
    )

    Crm::FollowUps::SnoozeHandler.apply(follow_up) if follow_up.pending?
    Crm::FollowUps::CardNextDueUpdater.update(@card)
    log_activity('automation_follow_up_created', follow_up_id: follow_up.id)
    Result.ok(follow_up_id: follow_up.id)
  end

  def build_follow_up_metadata
    raw = config['metadata'].presence || {}
    Crm::FollowUps::MetadataSanitizer.new(
      metadata: raw,
      automation_mode: config['automation_mode'].presence || 'reminder_only'
    ).perform
  end

  def assign_owner!
    owner = resolve_owner!
    return Result.failed('owner_not_found') if owner.blank?

    @card.update!(owner: owner, last_activity_at: Time.current)
    log_activity('automation_owner_assigned', owner_id: owner.id)
    Result.ok(owner_id: owner.id)
  end

  def resolve_owner!
    if ActiveModel::Type::Boolean.new.cast(config['use_card_owner'])
      return @card.owner if @card.owner_id.present?
    end

    owner_id = config['owner_id'].presence
    return if owner_id.blank?

    @card.account.users.joins(:account_users).find_by(id: owner_id, account_users: { account_id: @card.account_id })
  end

  def move_stage!
    depth = @automation_context[:depth].to_i
    return Result.failed('automation_depth_exceeded') if depth >= MAX_AUTOMATION_DEPTH

    target_stage = @card.account.crm_pipeline_stages.find_by(id: config['target_stage_id'])
    return Result.failed('target_stage_not_found') if target_stage.blank?
    return Result.ok(skipped: true) if @card.stage_id == target_stage.id

    Crm::Cards::Mover.new(
      card: @card,
      actor: @actor,
      target_stage: target_stage,
      automation_context: @automation_context.merge(depth: depth + 1)
    ).perform

    log_activity('automation_stage_moved', target_stage_id: target_stage.id)
    Result.ok(target_stage_id: target_stage.id)
  end

  def log_activity(event_type, payload)
    Crm::ActivityLogger.new(
      card: @card,
      actor: @actor,
      event_type: event_type,
      payload: payload.merge(
        stage_automation_id: @step.stage_automation_id,
        stage_automation_step_id: @step.id
      )
    ).perform
  end
end
