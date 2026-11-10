module Concerns::CallAgentLegs
  extend ActiveSupport::Concern

  AGENT_LEG_JOIN_GRACE_SECONDS = 30

  class_methods do
    # The attempt ID links an API reservation to its matching TwiML request.
    def pending_agent_leg(attempt)
      "pending:#{attempt}"
    end
  end

  def agent_legs
    meta&.fetch('agent_legs', nil) || {}
  end

  def agent_leg_join_wait(except: nil)
    now = Time.zone.now.to_i
    joining = agent_legs.except(except.to_s).values.select { |leg| leg['state'] == 'joining' && leg['at'].to_i > now - AGENT_LEG_JOIN_GRACE_SECONDS }
    joining.map { |leg| leg['at'].to_i + AGENT_LEG_JOIN_GRACE_SECONDS - now }.max&.clamp(1..)
  end

  def agent_leg_joined?(except: nil, since: nil)
    agent_legs.except(except.to_s).values.any? { |leg| leg['state'] == 'joined' && (since.nil? || leg['at'].to_i >= since) }
  end

  def open_agent_leg!(sid, attempt: nil)
    with_lock do
      leg_state = agent_legs.dig(sid.to_s, 'state')
      # A ring timeout under way is moving the caller out, so a late leg would find nobody
      next false if terminal? || leg_state == 'gone' || (ringing? && ring_timeout_in_progress?)

      if attempt.present?
        self.class.where(id: id).update_all(['meta = meta #- ARRAY[?, ?]', 'agent_legs', self.class.pending_agent_leg(attempt)]) # rubocop:disable Rails/SkipsModelValidations
      end
      record_agent_leg!(sid, 'joining') unless leg_state == 'joined'
      true
    end
  end

  # The caller holds the row lock; out-of-order callbacks cannot revive a gone leg.
  def record_agent_leg!(sid, state)
    return if sid.blank? || agent_legs.dig(sid, 'state') == 'gone'

    leg = { sid => { 'state' => state, 'at' => Time.zone.now.to_i } }
    self.class.where(id: id).update_all( # rubocop:disable Rails/SkipsModelValidations
      ["meta = jsonb_set(COALESCE(meta, '{}'::jsonb), '{agent_legs}', COALESCE(meta->'agent_legs', '{}'::jsonb) || ?::jsonb)", leg.to_json]
    )
    reload
  end

  def unanswered_by_failed_join?
    status == 'no_answer' && meta&.dig('unanswered_by_failed_join').present?
  end

  # Called under the row lock
  def retire_pending_agent_legs!
    legs = agent_legs.reject { |sid, _| sid.start_with?('pending:') }
    self.class.where(id: id).update_all(["meta = jsonb_set(COALESCE(meta, '{}'::jsonb), '{agent_legs}', ?::jsonb)", legs.to_json]) # rubocop:disable Rails/SkipsModelValidations
    reload
  end
end
