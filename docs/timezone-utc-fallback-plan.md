# CRM Timezone Fail-Closed Fix — Execution Plan

Branch: `fix/timezone-utc-fallback`. Reconstructed from scratch (prior 6 commits
were never pushed and are lost). Execute in ONE pass on a fresh context, then run
tests + rubocop, then a single local commit. NO push, NO deploy.

## Root cause

A user schedules `08:00` meaning 08:00 in THEIR timezone. When the tz can't be
resolved, the code silently assumes UTC, so `08:00 America/Sao_Paulo` fires at
`05:00` local. Three duplicated silent-UTC precedence blocks + scattered
`ActiveSupport::TimeZone[x] || ActiveSupport::TimeZone['UTC']` and `Time.zone.parse`.

Verified env: Rails 7.1.5.2, Ruby 3.4.4. `ActiveSupport::TimeZone['America/Sao_Paulo']`
is valid; `.parse('2026-07-08 08:00:00').utc` => 11:00. Invalid name => nil.
rbenv/bundle/rspec run fine in this path (~/dev, not ~/Documents, so no macOS TCC block).

## Step 1 — NEW central resolver

Create `app/services/crm/timezone/resolver.rb`:

```ruby
module Crm
  module Timezone
    # Central, fail-closed timezone resolver for CRM scheduling paths.
    # Precedence: explicit -> contact.additional_attributes['timezone'] ->
    # account.reporting_timezone -> (none valid) nil / raise. UTC is NEVER a
    # silent fallback; only used if a caller passes 'UTC' explicitly.
    class Resolver
      Unresolvable = Class.new(StandardError)

      def initialize(explicit: nil, contact: nil, account: nil)
        @explicit = explicit
        @contact = contact
        @account = account
      end

      def name
        candidates.each do |raw|
          candidate = raw.to_s.strip
          next if candidate.blank?
          return candidate if ActiveSupport::TimeZone[candidate].present?
        end
        nil
      end

      def name!
        name || raise(Unresolvable, 'no valid CRM timezone (explicit, contact, account all missing/invalid)')
      end

      def zone
        resolved = name
        resolved && ActiveSupport::TimeZone[resolved]
      end

      def zone!
        ActiveSupport::TimeZone[name!]
      end

      private

      def candidates
        [@explicit, contact_timezone, account_timezone]
      end

      def contact_timezone
        @contact&.additional_attributes.to_h['timezone']
      end

      def account_timezone
        @account.try(:reporting_timezone)
      end
    end
  end
end
```

## Step 2 — wire each surface (exact old -> new)

### app/services/crm/ai/config.rb  (delegate; KEEP UTC — informational caller context_builder)
OLD:
```ruby
      def self.resolved_timezone(account:, contact: nil)
        contact_tz = contact&.additional_attributes.to_h['timezone'].presence
        return contact_tz if ActiveSupport::TimeZone[contact_tz.to_s].present?

        account_tz = account&.try(:reporting_timezone).presence
        ActiveSupport::TimeZone[account_tz.to_s].present? ? account_tz : 'UTC'
      end
```
NEW:
```ruby
      def self.resolved_timezone(account:, contact: nil)
        Crm::Timezone::Resolver.new(contact: contact, account: account).name || 'UTC'
      end
```
(context_builder.rb:47 keeps working: informational tz for the AI prompt.)

### app/services/crm/follow_ups/params_resolver.rb  (manual follow-up; fail-closed)
OLD:
```ruby
  def resolved_timezone
    @attributes[:timezone].presence || @account.try(:reporting_timezone).presence || 'UTC'
  end
```
NEW:
```ruby
  def resolved_timezone
    Crm::Timezone::Resolver.new(
      explicit: @attributes[:timezone],
      contact: contact,
      account: @account
    ).name!
  end

  def contact
    @contact ||= @card.try(:contact) || @conversation&.contact
  end
```

### app/services/crm/follow_ups/auto_followup_touch_builder.rb  (touch #1 and #2+ shared)
initialize — add `timezone: nil` param + `@timezone = timezone`:
OLD:
```ruby
      def initialize(card:, touch:, due_at:, template_metadata: {})
        @card = card
        @touch = touch.to_i
        @due_at = due_at
        @template_metadata = (template_metadata || {}).to_h.stringify_keys
      end
```
NEW:
```ruby
      def initialize(card:, touch:, due_at:, timezone: nil, template_metadata: {})
        @card = card
        @touch = touch.to_i
        @due_at = due_at
        @timezone = timezone
        @template_metadata = (template_metadata || {}).to_h.stringify_keys
      end
```
timezone method:
OLD:
```ruby
      def timezone
        @card.account.try(:reporting_timezone).presence || 'UTC'
      end
```
NEW:
```ruby
      def timezone
        @timezone.presence ||
          Crm::Timezone::Resolver.new(contact: @card.contact, account: @card.account).name!
      end
```

### app/services/crm/follow_ups/auto_followup_planner.rb  (touch #1)
create_first_touch (first lines + builder call):
OLD:
```ruby
      def create_first_touch(card, last_inbound)
        due_at = compute_first_due(last_inbound.created_at, card)

        follow_up = Crm::FollowUps::AutoFollowupTouchBuilder.new(
          card: card,
          touch: 1,
          due_at: due_at
        ).perform
```
NEW:
```ruby
      def create_first_touch(card, last_inbound)
        timezone = resolved_timezone(card)
        return unresolvable_timezone(card) if timezone.blank?

        due_at = compute_first_due(last_inbound.created_at, timezone)

        follow_up = Crm::FollowUps::AutoFollowupTouchBuilder.new(
          card: card,
          touch: 1,
          due_at: due_at,
          timezone: timezone
        ).perform
```
add helper:
```ruby
      # Fail-closed: no resolvable tz => do NOT schedule touch #1 at a guessed UTC
      # wall time. Skip + log; the card is re-eligible once a valid tz exists.
      def unresolvable_timezone(card)
        Rails.logger.warn("[crm][auto_followup] skip card=#{card.id} no resolvable timezone")
        nil
      end
```
plan_for — replace the two trailing lines `create_first_touch(card, last_inbound)` + `true` with:
```ruby
        create_first_touch(card, last_inbound).present?
```
compute_first_due (card -> timezone):
OLD:
```ruby
      def compute_first_due(last_inbound_at, card)
        target = last_inbound_at + first_interval_hours.hours
        target = @now if target < @now
        clamp_into_quiet_hours(target, card)
      end
```
NEW:
```ruby
      def compute_first_due(last_inbound_at, timezone)
        target = last_inbound_at + first_interval_hours.hours
        target = @now if target < @now
        clamp_into_quiet_hours(target, timezone)
      end
```
clamp_into_quiet_hours (card -> timezone; zone from timezone) — first 8 lines:
OLD:
```ruby
      def clamp_into_quiet_hours(time, card)
        quiet = @config[:quiet_hours].to_h
        start_hour = quiet['start'].to_i
        end_hour = quiet['end'].to_i
        return time if start_hour >= end_hour

        zone = quiet_hours_zone(card)
        local = time.in_time_zone(zone)
```
NEW:
```ruby
      def clamp_into_quiet_hours(time, timezone)
        quiet = @config[:quiet_hours].to_h
        start_hour = quiet['start'].to_i
        end_hour = quiet['end'].to_i
        return time if start_hour >= end_hour

        zone = ActiveSupport::TimeZone[timezone]
        local = time.in_time_zone(zone)
```
replace quiet_hours_zone entirely:
OLD:
```ruby
      def quiet_hours_zone(card)
        contact = card.contact
        contact_tz = contact&.additional_attributes.to_h['timezone'].presence
        return contact_tz if ActiveSupport::TimeZone[contact_tz.to_s].present?

        account_tz = @pipeline.account.try(:reporting_timezone).presence
        ActiveSupport::TimeZone[account_tz.to_s].present? ? account_tz : 'UTC'
      end
```
NEW:
```ruby
      # Resolves the cadence timezone (contact -> account.reporting_timezone),
      # fail-open to nil. MUST match AutoFollowupRunner#resolved_timezone so touch #1
      # (planner) and touch #2+ (runner) clamp to the SAME local window. nil => skip.
      def resolved_timezone(card)
        Crm::Timezone::Resolver.new(contact: card.contact, account: @pipeline.account).name
      end
```

### app/services/crm/follow_ups/auto_followup_runner.rb  (touch #2+)
schedule_next_touch (inside `if touch < max_touches`):
OLD:
```ruby
      def schedule_next_touch
        if touch < max_touches
          next_touch = touch + 1
          due_at = compute_due(last_inbound_at + interval_hours(next_touch).hours)
          Crm::FollowUps::AutoFollowupTouchBuilder.new(card: @card, touch: next_touch, due_at: due_at).perform
          merge_state!('active' => true, 'touch' => next_touch, 'next_due_at' => due_at.iso8601)
```
NEW:
```ruby
      def schedule_next_touch
        if touch < max_touches
          next_touch = touch + 1
          timezone = resolved_timezone
          return mark_cadence_unresolvable if timezone.blank?

          due_at = compute_due(last_inbound_at + interval_hours(next_touch).hours, timezone)
          Crm::FollowUps::AutoFollowupTouchBuilder.new(card: @card, touch: next_touch, due_at: due_at, timezone: timezone).perform
          merge_state!('active' => true, 'touch' => next_touch, 'next_due_at' => due_at.iso8601)
```
reschedule_for_cap:
OLD: `next_due = compute_due(@now + MARKETING_CAP_WINDOW)`
NEW: `next_due = compute_due(@now + MARKETING_CAP_WINDOW, resolved_timezone)`
compute_due (signature + tz-blank guard + zone from timezone) — first lines:
OLD:
```ruby
      def compute_due(candidate)
        quiet = config['quiet_hours'].to_h
        start_hour = quiet['start'].presence&.to_i
        end_hour = quiet['end'].presence&.to_i
        return candidate if start_hour.blank? || end_hour.blank?

        local = candidate.in_time_zone(quiet_time_zone)
```
NEW:
```ruby
      def compute_due(candidate, timezone = resolved_timezone)
        return candidate if timezone.blank?

        quiet = config['quiet_hours'].to_h
        start_hour = quiet['start'].presence&.to_i
        end_hour = quiet['end'].presence&.to_i
        return candidate if start_hour.blank? || end_hour.blank?

        local = candidate.in_time_zone(ActiveSupport::TimeZone[timezone])
```
replace quiet_time_zone with resolved_timezone + add mark_cadence_unresolvable:
OLD:
```ruby
      def quiet_time_zone
        contact = @follow_up.contact || @card.contact
        contact_tz = contact&.additional_attributes.to_h['timezone'].presence
        return contact_tz if ActiveSupport::TimeZone[contact_tz.to_s].present?

        account_tz = @card.account.try(:reporting_timezone).presence
        ActiveSupport::TimeZone[account_tz.to_s].present? ? account_tz : 'UTC'
      end
```
NEW:
```ruby
      # MUST match AutoFollowupPlanner#resolved_timezone. Fail-open to nil.
      def resolved_timezone
        Crm::Timezone::Resolver.new(
          contact: @follow_up.contact || @card.contact, account: @card.account
        ).name
      end

      # Fail-closed: no resolvable tz => stop the cadence rather than schedule the
      # next touch at a guessed UTC wall time.
      def mark_cadence_unresolvable
        merge_state!('active' => false, 'spent' => true,
                     'stopped_reason' => 'unresolvable_timezone', 'next_due_at' => nil)
        log_activity('ai_followup_stopped', touch: touch, reason: 'unresolvable_timezone')
      end
```

### app/services/crm/follow_ups/callback_scheduler.rb
resolve_due_at (first 2 lines):
OLD:
```ruby
      def resolve_due_at
        zone = ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['UTC']
        local = zone.parse(@callback[:requested_at].to_s)
```
NEW:
```ruby
      def resolve_due_at
        return if timezone.blank?

        zone = ActiveSupport::TimeZone[timezone]
        local = zone.parse(@callback[:requested_at].to_s)
```
timezone method:
OLD: `@timezone ||= Config.resolved_timezone(account: @card.account, contact: contact)`
NEW: `@timezone ||= Crm::Timezone::Resolver.new(contact: contact, account: @card.account).name`

### app/services/crm/ai/suggest_meeting_time_service.rb
perform (add guard at top):
OLD:
```ruby
      def perform
        slots = free_slots
        return [] if slots.empty?
```
NEW:
```ruby
      def perform
        return [] if timezone.blank?

        slots = free_slots
        return [] if slots.empty?
```
time_zone:
OLD: `@time_zone ||= ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['UTC']`
NEW: `@time_zone ||= (ActiveSupport::TimeZone[timezone] if timezone.present?)`
default_timezone:
OLD: `Crm::Ai::Config.resolved_timezone(account: card.account, contact: card.contact)`
NEW: `Crm::Timezone::Resolver.new(account: card.account, contact: card.contact).name`

### app/models/crm/agent_booking_profile.rb
resolved_timezone (non-raising accessor; nil if unresolvable):
OLD:
```ruby
  def resolved_timezone
    timezone.presence || 'UTC'
  end
```
NEW:
```ruby
  def resolved_timezone
    Crm::Timezone::Resolver.new(explicit: timezone, account: account).name
  end
```

### app/services/crm/calendar/public_available_slots.rb
time_zone:
OLD: `@time_zone ||= ActiveSupport::TimeZone[profile.resolved_timezone] || ActiveSupport::TimeZone['UTC']`
NEW: `@time_zone ||= (ActiveSupport::TimeZone[profile.resolved_timezone] if profile.resolved_timezone.present?)`
local_day (guard nil time_zone — else nil.parse NoMethodError escapes rescue):
OLD:
```ruby
      def local_day
        @local_day ||= begin
          time_zone.parse("#{date} 00:00:00")
        rescue ArgumentError, TypeError
          nil
        end
      end
```
NEW:
```ruby
      def local_day
        @local_day ||= begin
          return nil if time_zone.blank?

          time_zone.parse("#{date} 00:00:00")
        rescue ArgumentError, TypeError
          nil
        end
      end
```
(perform already `return strict_empty if local_day.blank?` => public page shows no slots.)

### app/services/whatsapp_api_campaigns/creator.rb
campaign_attributes hash: `scheduled_at: Time.zone.parse(permitted[:scheduled_at].to_s)` -> `scheduled_at: scheduled_at`
add private method:
```ruby
    def scheduled_at
      zone = Crm::Timezone::Resolver.new(account: @account).zone
      raise ArgumentError, 'unresolvable_timezone_for_schedule' if zone.nil?

      zone.parse(permitted[:scheduled_at].to_s)
    end
```
(zone.parse respects an offset in the string, else applies the zone — safer than Time.zone.parse.)

## Step 3 — specs (spec/support/crm_helpers.rb has create_crm_pipeline/create_crm_agent/etc.; accounts factory exists)

- `spec/services/crm/timezone/resolver_spec.rb` — precedence (explicit > contact > account);
  invalid explicit falls through; all-invalid => name nil + name!/zone! raise Unresolvable;
  `zone.parse('2026-07-08 08:00:00').utc.hour == 11` for America/Sao_Paulo (NOT 8).
- `spec/services/crm/follow_ups/params_resolver_spec.rb` — explicit honored; precedence; raises when none.
- `spec/services/crm/follow_ups/auto_followup_touch_builder_spec.rb` — stores explicit tz; resolves from card; raises when none.
- `spec/services/crm/follow_ups/callback_scheduler_spec.rb` — requested_at 08:00 local (tz America/Sao_Paulo) => due_at.utc.hour == 11 (not 8); nil (no follow_up) when unresolvable.
- `spec/services/crm/ai/suggest_meeting_time_service_spec.rb` — returns [] when tz unresolvable.
- `spec/services/whatsapp_api_campaigns/creator_spec.rb` — scheduled_at 08:00 local (account.reporting_timezone America/Sao_Paulo) => stored scheduled_at.utc.hour == 11; raises ArgumentError when unresolvable.
- GAP: touch #2+ full runner send-loop + public_available_slots not unit-spec'd (heavy setup).
  Covered indirectly via shared Resolver + TouchBuilder + compute_due edits. Flag in report; add runner spec if time allows.

Fixtures: `account.update!(reporting_timezone: 'America/Sao_Paulo')` (store_accessor on settings);
`contact.update!(additional_attributes: { 'timezone' => 'America/Sao_Paulo' })`.

## Step 4 — validate + commit

```
eval "$(rbenv init - zsh)"
bundle exec rspec spec/services/crm/timezone/resolver_spec.rb \
  spec/services/crm/follow_ups/params_resolver_spec.rb \
  spec/services/crm/follow_ups/auto_followup_touch_builder_spec.rb \
  spec/services/crm/follow_ups/callback_scheduler_spec.rb \
  spec/services/crm/ai/suggest_meeting_time_service_spec.rb \
  spec/services/whatsapp_api_campaigns/creator_spec.rb
bundle exec rspec spec/services/crm/follow_ups spec/services/crm/ai   # regression
bundle exec rubocop -a <all changed files>
```
Commit (local only, NO push/deploy):
`fix(crm): fail-closed CRM timezone resolver for scheduling (no silent UTC)`

## Behavior change to flag to Rodrigo
Fail-closed now RAISES / skips for accounts with NO explicit tz AND no valid
account.reporting_timezone (previously silently UTC). In practice the browser sends
an explicit tz for manual follow-ups and account 6 should have reporting_timezone set.
Live-05h mitigation: set `reporting_timezone = America/Sao_Paulo` on the affected
account (drives follow-up/auto/campaign tz here — not only reports).
