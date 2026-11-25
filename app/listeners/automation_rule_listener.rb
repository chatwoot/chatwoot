class AutomationRuleListener < BaseListener
  # How long a rule execution on a message is remembered, which is what a later recovery of that message
  # reads to know the rule already ran. The message a placeholder stands for arrives when the sender's
  # phone comes back online to encrypt it again, so days later is normal and there is no upper bound
  # worth honouring: past this, a recovery may run that one rule a second time.
  RULE_RUN_CLAIM_EXPIRY = 30.days

  # What a claim holds once the execution that took it has finished. A claim is one key doing two jobs --
  # "this rule has run for this message" and "somebody is running it right now" -- and telling them apart
  # is what lets the arrival record end without taking a failed action's retry with it (#666).
  CLAIM_DONE = 'done'.freeze

  # The events that speak of a body rather than of a row appearing. Each of them names the body it is
  # about, and `announced_body_current?` is what makes that name mean something.
  BODY_SCOPED_EVENTS = [Events::Types::MESSAGE_RECOVERED, Events::Types::MESSAGE_EDITED].freeze

  def conversation_updated(event)
    process_conversation_event(event, 'conversation_updated')
  end

  def conversation_created(event)
    process_conversation_event(event, 'conversation_created')
  end

  def conversation_opened(event)
    process_conversation_event(event, 'conversation_opened')
  end

  def conversation_resolved(event)
    process_conversation_event(event, 'conversation_resolved')
  end

  def message_created(event)
    # Before the rules, not after: a recovery arriving in between has to find the arrival on record, and
    # the claims are what keep it from repeating whatever this evaluation is about to do.
    track_arrival(event.data[:message])
    process_message_event(event)
    arm_inactivity(event)
  end

  # The body of a message that was stored before it could be read has arrived into that same row. Rules
  # are evaluated again, against the content this time: a rule filtered on it never saw a body at the
  # arrival, and MESSAGE_UPDATED reaches no automation (fazer-ai/chatwoot#491).
  #
  # Re-firing `message_created` instead would run every rule that does not filter on content a second
  # time, which is worse than the miss: an auto-reply answering twice, a webhook delivered twice.
  # Only for a placeholder whose arrival this mechanism handled. A row stored before this was deployed,
  # or before its record expired, ran its rules with no claim written, so evaluating again would run the
  # ones that do not filter on content a second time: an auto-reply answering a message from before the
  # upgrade, which is the outcome this whole design exists to avoid. Then the content is the only thing
  # missed, which is what every such row had already settled for.
  def message_recovered(event)
    message = event.data[:message]
    return unless arrival_tracked?(message)

    forget_arrival(message) if process_message_event(event)
  end

  # Somebody changed what a message says, and the rules that answer to it are the ones whose trigger is
  # this event: a rule opts in, rather than every `message_created` rule being asked a second question.
  # An edit is not a second arrival, and the difference is visible in the actions -- an auto-reply
  # answering a typo correction is the outcome that keeps this off `message_created` (#648).
  def message_edited(event)
    process_message_event(event, 'message_edited')
    arm_inactivity(event)
  end

  private

  # Answers whether this execution finished the question the announcement asked, which only
  # `message_recovered` reads. It is decided rule by rule inside the lock, where the row is the one the
  # decision was made against, and never from the row as it reads afterwards: the body is being written
  # to throughout this window -- that is the whole subject -- so a second look is a different question
  # with the same words (#666).
  #
  # An event nothing subscribes to and an event with no rules are both finished: there was nothing to
  # ask. An ignored event is not, because it was never asked at all.
  def process_message_event(event, event_name = 'message_created')
    message = event.data[:message]

    return false if ignore_message_created_event?(event)

    account = message.try(:account)
    changed_attributes = event.data[:changed_attributes]

    return true if account.blank?

    rules = current_account_rules(event_name, account)
    return true if rules.blank?

    rules.map do |rule|
      claimed = claim_matching_rule(rule, message, event, event_name, changed_attributes)

      execute_claimed_rule(rule, account, message, claimed[:key], claimed[:token]) if claimed[:token]
      claimed[:concluded]
    end.all?
  end

  # An announcement that speaks of a body says which body, and this is where the row is asked whether it
  # is still showing it. The conditions are evaluated against the row (`ConditionsFilterService` queries
  # it), never against the payload, and this job runs long after the dispatch: a write that landed in
  # between would have the rules answer about a body the announcement is not about -- the body a recovery
  # carried, on a row an edit has since replaced (#661), or the first of two edits on a row the second
  # already wrote over (#660). The write that won carries its own announcement, so the one that lost has
  # nothing left to do and leaves quietly. Asked inside the row lock its caller holds, against the row
  # that lock reloaded: asked once on the way in, an edit committing before the lock would pass it with
  # the old body and then be evaluated with the new one.
  #
  # `MESSAGE_CREATED` is deliberately not one of these. An arrival is about the row appearing, not about a
  # body: it names none, and it keeps answering about whatever the row says by the time the work runs. A
  # content rule that found nothing there is what `MESSAGE_RECOVERED` exists to ask a second time.
  #
  # An announcement that carries no `content` at all named no body, and there is nothing to check. That
  # is what every one of these dispatched before this shipped looks like, and they are sitting in the
  # queue and in the retry set while it deploys: reading their silence as an empty body would compare it
  # with a message that says something, and discard the lot of them without a trace. What keeps that
  # silence from also meaning a caller who forgot is a fence over the source, in
  # `spec/listeners/announced_body_dispatch_fence_spec.rb`: every dispatch of one of these names a body.
  def announced_body_current?(event, message)
    return true unless body_scoped?(event)
    return true unless event.data.key?(:content)

    message.content.to_s == event.data[:content].to_s
  end

  # The body the announcement named, the body the conditions answer about and the body the claim is taken
  # on all have to be the same one. They are read separately -- the conditions by a query, the key off the
  # row this job loaded -- and a write committing between any two of them would have this execution
  # answer about one body while claiming another: the older body's key taken while acting on the newer,
  # leaving the newer body's own key free for a second run of the same rule, or a check that passed
  # against the row as it was loaded and conditions that read the row as it is now.
  #
  # So the row is locked for every event that names a body, and `with_lock` reloads it, which is what
  # makes the check inside worth anything. An arrival names none and keys on the message, which does not
  # move, so it pays nothing. The actions always run outside the lock, because they send messages and
  # call webhooks.
  def claim_matching_rule(rule, message, event, event_name, changed_attributes)
    return evaluate_and_claim(rule, message, event, event_name, changed_attributes) unless body_scoped?(event)

    message.with_lock { evaluate_and_claim(rule, message, event, event_name, changed_attributes) }
  end

  def body_scoped?(event) = BODY_SCOPED_EVENTS.include?(event.name.to_s)

  # The claim is asked for after the conditions and only when they match, never before: a rule that did
  # not match while the row was a placeholder has to be left free to run when the content arrives.
  #
  # `present?` rather than `blank?`, because that is the question the rule's own filter answers and the
  # two differ for anything that defines only one of them.
  # `concluded` says whether this rule's question is finished, and it is false in exactly two cases.
  #
  # The row has stopped showing the body the announcement named: nothing was asked, and something has to
  # ask again once that body is back. And the claim belongs to an execution that has not finished: that
  # one owns the rule and may still be acting on it, so concluding here would drop the arrival record out
  # from under its retry if its action fails and it comes back.
  #
  # A claim that is already finished does conclude, and the distinction is the whole reason `CLAIM_DONE`
  # exists. The ordinary placeholder carries one: a rule that does not filter on content matched at the
  # arrival and ran there, and its claim then sits for thirty days. Reading that as "somebody is still
  # working on it" would leave the arrival record standing for every such account, for good, which is the
  # case this whole mechanism is about.
  #
  # A rule whose conditions do not match is finished: it was asked and it answered no.
  def evaluate_and_claim(rule, message, event, event_name, changed_attributes)
    return { concluded: false } unless announced_body_current?(event, message)

    conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, message.conversation,
                                                                      { message: message, changed_attributes: changed_attributes }).perform
    return { concluded: true } unless conditions_match.present? # rubocop:disable Rails/Blank -- see the note above: not the same question

    key = claim_key_for(event_name, rule, message)
    token = claim(key)

    { key: key, token: token, concluded: token.present? || claim_finished?(key) }
  end

  # Asked only of a key this attempt did not take, so the answer is about somebody else's execution. A
  # read that fails answers no, which keeps the arrival record standing: the cost of that is a repeated
  # announcement the run claims absorb, and the cost of the opposite is a lost automation.
  def claim_finished?(key)
    Redis::Alfred.get(key) == CLAIM_DONE
  rescue StandardError => e
    Rails.logger.warn("[AUTOMATION] could not read the run claim #{key}: #{e.message}")
    false
  end

  # What the claim is about, and the two events answer it differently.
  #
  # For the arrival and the recovery it is the message: the two are one message becoming readable once,
  # so a rule runs for it once.
  #
  # For an edit it is the body. "Has this rule already run for this message" would let only the first of
  # two edits run, and two edits are two events. "Has this rule already run for this message against
  # this body" keeps both of those and still answers for the case that costs a duplicate action: two
  # edits committing before either job runs leave both evaluations reading the same stored body, since
  # the conditions are asked of the row and not of the event, and they are then the same run. The cost
  # is an edit that restores a body this rule already ran on, which does not run again.
  def claim_key_for(event_name, rule, message)
    return claim_key(rule, message) unless event_name == 'message_edited'

    format(Redis::RedisKeys::AUTOMATION_RULE_MESSAGE_BODY_RUN, rule_id: rule.id, message_id: message.id,
                                                               body: Digest::SHA256.hexdigest(message.content.to_s)[0, 16])
  end

  # At most one execution of this rule for this message, counting the arrival and the recovery that
  # filled a placeholder in. Claimed on both paths and not only on the recovery: nothing orders the two
  # jobs, so the arrival may well be the one that evaluates after the content landed, and a claim it
  # skipped is one the recovery would take for a rule that already ran.
  #
  # Atomic, because both may find the same rule matching; the one that takes the key is the one that
  # acts. Answers false when the key is already there. A key lost before the recovery (an expiry, a
  # Redis that was replaced) costs a second run of that one rule, which is why the window is long.
  # Answers this attempt's own token when it took the key, and nothing when the key was already there,
  # which is the rule having run.
  #
  # The token is what makes the release safe. When the answer to the write is what was lost, Redis may
  # well have taken the key, and a claim nobody could read is a rule that never ran holding its own
  # record for thirty days. But the key may equally belong to an execution that already happened -- the
  # arrival's, with the recovery now asking -- and deleting that one would let the retry run the rule a
  # second time. So only a key carrying this attempt's token is released.
  def claim(key)
    token = SecureRandom.uuid
    taken = Redis::Alfred.set(key, token, nx: true, ex: RULE_RUN_CLAIM_EXPIRY)

    token if taken
  rescue StandardError
    release_claim(key, token)
    raise
  end

  # A rule whose execution raised before it did anything must be free to run on the retry of this job:
  # holding the claim would spend the whole window on an attempt that never acted, and for a delayed rule
  # the attempt is only a row in `automation_rule_pending_executions`, which failed to be written.
  # Releasing restores exactly what happens today, where a retry evaluates and acts again.
  def execute_claimed_rule(rule, account, message, key, token)
    execute_rule(rule, account, message.conversation, message: message)
    finish_claim(key)
  rescue StandardError
    release_claim(key, token)
    raise
  end

  # The rule has run, so the claim stops meaning "somebody is working on this" and starts meaning "this
  # happened". Best effort: a write that fails leaves the claim as a token, which still keeps the rule
  # from running twice and only costs the arrival record its chance to end.
  def finish_claim(key)
    Redis::Alfred.set(key, CLAIM_DONE, ex: RULE_RUN_CLAIM_EXPIRY)
  rescue StandardError => e
    Rails.logger.warn("[AUTOMATION] could not mark the run claim #{key} finished: #{e.message}")
  end

  # Best effort on the way out of a failure that is already being raised: a delete that fails too would
  # replace the error the caller needs to see with one about Redis.
  def release_claim(key, token)
    Redis::Alfred.delete_if_equals(key, token)
  rescue StandardError => e
    Rails.logger.warn("[AUTOMATION] could not release the run claim #{key}: #{e.message}")
  end

  def claim_key(rule, message)
    format(Redis::RedisKeys::AUTOMATION_RULE_MESSAGE_RUN, rule_id: rule.id, message_id: message.id)
  end

  # Recorded for a placeholder only, which is the only row a recovery can follow, so the ordinary message
  # pays nothing for this.
  def track_arrival(message)
    return unless placeholder?(message)

    Redis::Alfred.set(arrival_key(message), Time.current.to_i, ex: RULE_RUN_CLAIM_EXPIRY)
  end

  def arrival_tracked?(message)
    Redis::Alfred.exists?(arrival_key(message))
  end

  # The record exists so that a recovery of this placeholder is evaluated once, and it is gone the moment
  # one has been. What keeps it standing is a recovery that could not be evaluated because the row had
  # stopped showing the body its announcement named: that announcement is still owed an answer, and the
  # write-back that puts the body back is what asks again (#666).
  #
  # Without this the record would outlive the answer for its whole thirty days, and a refused edit on a
  # message recovered long ago would re-open the arrival rules against whatever rules the account has by
  # then -- an auto-reply answering a message from weeks back because an agent's edit failed to send.
  def forget_arrival(message)
    Redis::Alfred.delete(arrival_key(message))
  rescue StandardError => e
    Rails.logger.warn("[AUTOMATION] could not clear the arrival record #{arrival_key(message)}: #{e.message}")
  end

  def arrival_key(message)
    format(Redis::RedisKeys::AUTOMATION_MESSAGE_ARRIVAL_TRACKED, message_id: message.id)
  end

  # A row stored for a message this side could not read yet. `unsupported_reason` is written by the
  # WhatsApp session layer alone, and only for a body that may still arrive under the same id.
  def placeholder?(message)
    message.try(:content_attributes).to_h['unsupported_reason'].present?
  end

  def process_conversation_event(event, event_name)
    return arm_inactivity(event) if performed_by_automation?(event)

    auto_reply_skip_events = %w[conversation_created conversation_opened]
    return if auto_reply_skip_events.include?(event_name) && ignore_auto_reply_event?(event)

    conversation = event.data[:conversation]
    account = conversation.account
    changed_attributes = event.data[:changed_attributes]

    rules = conversation_rules(event_name, account)
    return if rules.blank?

    rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, conversation, { changed_attributes: changed_attributes }).perform
      execute_rule(rule, account, conversation, at: event.timestamp) if conditions_match.present?
    end
  end

  # A delayed conversation rule reads as "the conversation has been in this status for N minutes",
  # so a conversation created in that status must arm it too. Creation never dispatches
  # CONVERSATION_UPDATED, and both paths key the episode on the same status_changed_at, so a later
  # update arming the same episode is deduped by the unique index.
  def conversation_rules(event_name, account)
    rules = current_account_rules(event_name, account)
    return rules unless event_name == 'conversation_created'

    rules + current_account_rules('conversation_updated', account).where.not(execution_delay: nil)
  end

  # Delayed rules record a pending execution instead of acting; the sweep re-checks and
  # runs them at due time. Flag off means no arming and no immediate fallback — a delayed
  # message silently becoming instant is worse than skipping.
  def execute_rule(rule, account, conversation, message: nil, at: nil)
    if rule.execution_delay.present?
      return unless account.feature_enabled?('delayed_automations')

      AutomationRulePendingExecution.schedule(rule: rule, conversation: conversation, message: message, at: at)
    else
      ::AutomationRules::ActionService.new(rule, account, conversation).perform
    end
  end

  def current_account_rules(event_name, account)
    AutomationRule.where(
      event_name: event_name,
      account_id: account.id,
      active: true
    )
  end

  # A message is the commonest activity there is, and neither its arrival nor its edit dispatches a
  # conversation event: last_activity_at is written with update_columns on a create, and an edit
  # moves no conversation timestamp at all. A wait on inactivity is conversation-level, so it arms
  # from here or it would fire on a conversation somebody is writing in.
  # Who wrote it is handed over rather than filtered here: which automation's writing counts as the
  # conversation being alive is the wait's own question, and it is answered where it is asked. That
  # is also why a rule's own conversation event reaches this after the early return above: its
  # writing is no reason to run the rules again, but it is still activity, and a wait on silence
  # that already ran is terminal, so no sweep will read it. The arm is the only thing left that can.
  def arm_inactivity(event)
    message = event.data[:message]
    return if message && (message.activity? || message.auto_reply_email?)

    conversation = message&.conversation || event.data[:conversation]
    ::AutomationRules::InactivityArmingService.new(
      conversation, message: message, performed_by: event.data[:performed_by], at: event.timestamp
    ).perform
  end

  def performed_by_automation?(event)
    event.data[:performed_by].present? && event.data[:performed_by].instance_of?(AutomationRule)
  end

  def ignore_auto_reply_event?(event)
    conversation = event.data[:conversation]
    conversation.additional_attributes['auto_reply'].present?
  end

  def ignore_message_created_event?(event)
    message = event.data[:message]
    performed_by_automation?(event) || message.activity? || message.auto_reply_email?
  end
end
