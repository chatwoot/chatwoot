module Crm
  module Calendar
    # Computes the bookable slots for a public booking profile on a single local
    # day. Reuses the S3 free/busy AvailabilityService (Google+MS parity inherent)
    # and subtracts busy intervals, then keeps only slots that:
    #   - fall on an allowed weekday + inside the profile working hours,
    #   - are in the future (with the buffer applied),
    #   - sit within the booking window (today .. today + booking_window_days),
    #   - do not overlap any busy interval (honoring the buffer on both sides).
    #
    # Fail-safe: any provider error inside AvailabilityService already degrades to
    # "no busy intervals"; this service additionally rescues to [] so the public
    # endpoint never leaks an error.
    class PublicAvailableSlots
      MAX_SLOTS = 200

      # strict:false (DISPLAY, default) — fail-safe: a provider error degrades to
      # an empty slot list (and may serve cached free/busy). strict:true (BOOKING
      # re-check) — fail-closed: a provider error PROPAGATES so the booking is
      # rejected rather than confirmed against unknown availability.
      # inbox/agent override the profile defaults for a PER-AGENT link: the slots are
      # then computed for that agent's chosen mailbox + that agent's availability.
      # When omitted (fixed mode) they fall back to the profile's inbox/assignee.
      def initialize(profile:, date:, strict: false, inbox: nil, agent: nil)
        @profile = profile
        @date = date
        @strict = strict
        @inbox = inbox
        @agent = agent
      end

      # Returns an array of ISO8601 start strings (with offset).
      def perform
        return strict_empty if local_day.blank?
        return strict_empty unless allowed_weekday?
        return strict_empty unless within_booking_window?

        candidate_starts.reject { |start_at| conflicts?(start_at) }
                        .first(MAX_SLOTS)
                        .map(&:iso8601)
      rescue StandardError => e
        raise e if strict

        Rails.logger.error("CRM public slots failed: #{e.class.name}")
        []
      end

      private

      attr_reader :profile, :date, :strict

      # The pre-slot guards (bad date / disallowed weekday / outside window) are
      # deterministic profile rules, not provider lookups, so an empty result here
      # is a real "no slots" answer and is safe to return even under strict.
      def strict_empty
        []
      end

      def duration
        profile.duration_minutes.minutes
      end

      def buffer
        profile.buffer_minutes.minutes
      end

      def time_zone
        # profile.resolved_timezone is never blank (name_or_default), so this is
        # always a valid ActiveSupport::TimeZone.
        @time_zone ||= ActiveSupport::TimeZone[profile.resolved_timezone]
      end

      def local_day
        @local_day ||= begin
          time_zone.parse("#{date} 00:00:00")
        rescue ArgumentError, TypeError
          nil
        end
      end

      def day_start
        local_day.change(hour: profile.start_hour)
      end

      def day_end
        # end_hour of 24 means midnight (end of day).
        profile.end_hour >= 24 ? local_day.end_of_day : local_day.change(hour: profile.end_hour)
      end

      def allowed_weekday?
        profile.weekdays.include?(local_day.wday)
      end

      def within_booking_window?
        today = Time.current.in_time_zone(time_zone).to_date
        booking_day = local_day.to_date
        booking_day >= today && booking_day <= (today + profile.booking_window_days.days)
      end

      def earliest_allowed_start
        Time.current + buffer
      end

      def candidate_starts
        slots = []
        cursor = day_start
        step = duration
        while cursor + duration <= day_end
          slots << cursor if cursor >= earliest_allowed_start
          cursor += step
        end
        slots
      end

      # A candidate conflicts if [start - buffer, start + duration + buffer] overlaps
      # any busy interval.
      def conflicts?(start_at)
        window_start = start_at - buffer
        window_end = start_at + duration + buffer
        busy_intervals.any? do |interval|
          window_start < interval[:end] && interval[:start] < window_end
        end
      end

      # Provider free/busy PLUS locally-scheduled meetings on the same mailbox.
      # The local set matters because provider free/busy lags (and is absent under
      # simulation): a meeting booked seconds ago must already hide its slot from
      # other public visitors, so the same window is not offered twice.
      def busy_intervals
        @busy_intervals ||= provider_busy_intervals + local_meeting_intervals
      end

      def provider_busy_intervals
        raw_busy_intervals.filter_map do |interval|
          start_at = safe_parse(interval[:start] || interval['start'])
          end_at = safe_parse(interval[:end] || interval['end'])
          next if start_at.blank? || end_at.blank?

          { start: start_at, end: end_at }
        end
      end

      def local_meeting_intervals
        # SHARED mailbox: AvailabilityService already returns THIS agent's meetings
        # (fresh). Adding the inbox-wide set here would re-introduce the cross-agent
        # over-block, so skip it.
        return [] if shared_calendar?

        # Dedicated mailbox: subtract this mailbox's just-booked meetings to cover
        # provider free/busy lag. Widen the load window by the buffer on both sides so
        # a meeting just OUTSIDE working hours still buffers the last in-hours slot.
        Crm::Meeting
          .where(account_id: profile.account_id, inbox_id: effective_inbox.id, status: :scheduled)
          .where('starts_at < ? AND ends_at > ?', day_end + buffer, day_start - buffer)
          .pluck(:starts_at, :ends_at)
          .map { |s, e| { start: s, end: e } }
      end

      def raw_busy_intervals
        Crm::Meetings::AvailabilityService.new(
          inbox: effective_inbox,
          date: date,
          timezone: profile.resolved_timezone,
          agent: @agent
        ).busy_intervals(strict: strict)
      end

      def effective_inbox
        @effective_inbox ||= @inbox || profile.inbox
      end

      def shared_calendar?
        channel = effective_inbox&.channel
        channel.is_a?(Channel::Email) && channel.calendar_shared?
      end

      def safe_parse(value)
        return if value.blank?

        Time.iso8601(value.to_s)
      rescue ArgumentError
        Time.zone.parse(value.to_s)
      end
    end
  end
end
