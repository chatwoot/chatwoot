<template>
  <div
    v-if="showSLATimer"
    class="flex items-center h-5 gap-1 w-fit truncate px-2 py-0.5 border border-solid rounded border-slate-75 dark:border-slate-600"
  >
    <fluent-icon
      size="14"
      :icon="slaStatus.icon"
      type="outline"
      :icon-lib="isSlaMissed ? 'lucide' : 'fluent'"
      class="flex-shrink-0"
      :class="
        isSlaMissed
          ? 'text-red-400 dark:text-red-300'
          : 'text-yellow-600 dark:text-yellow-500'
      "
    />
    <span
      class="text-xs font-medium"
      :class="
        isSlaMissed
          ? 'text-red-400 dark:text-red-300'
          : 'text-yellow-600 dark:text-yellow-500'
      "
    >
      {{ slaStatus.diff }}
    </span>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  props: {
    chat: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    ...mapGetters({
      activeSLA: 'sla/getSLAById',
    }),
    showSLATimer() {
      return this.slaPolicyId && this.slaStatus.diff;
    },
    slaPolicyId() {
      return this.chat?.sla_policy_id;
    },
    sla() {
      if (!this.slaPolicyId) return null;
      return this.activeSLA(this.slaPolicyId);
    },
    firstReplyTime() {
      return this.chat?.first_reply_created_at || 0;
    },
    waitingSince() {
      return this.chat?.waiting_since || 0;
    },
    createdAt() {
      return this.chat?.created_at || 0;
    },
    isSlaMissed() {
      return this.slaStatus?.isSlaMissed;
    },
    slaStatus() {
      if (!this.sla || !this.chat)
        return { type: '', diff: '', icon: '', isSlaMissed: false };

      const {
        first_response_time_threshold,
        next_response_time_threshold,
        resolution_time_threshold,
      } = this.sla || {};

      // Calculate time differences
      const frtDiff = this.calculateThreshold(
        'FRT',
        first_response_time_threshold
      );
      const nrtDiff = this.calculateThreshold(
        'NRT',
        next_response_time_threshold
      );
      const rtDiff = this.calculateThreshold('RT', resolution_time_threshold);

      // Array to hold the SLA breaches or upcoming breaches
      const breaches = [];

      // Check FRT only if threshold is not null and first reply hasn't been made
      if (
        first_response_time_threshold !== null &&
        (!this.firstReplyTime || this.firstReplyTime === 0)
      ) {
        breaches.push({
          type: 'FRT',
          diff: frtDiff,
          icon: frtDiff <= 0 ? 'flame' : 'alarm',
          isSlaMissed: frtDiff <= 0,
        });
      }

      // Check NRT only if threshold is not null, first reply has been made and we are waiting since
      if (
        next_response_time_threshold !== null &&
        this.firstReplyTime &&
        this.waitingSince
      ) {
        breaches.push({
          type: 'NRT',
          diff: nrtDiff,
          icon: nrtDiff <= 0 ? 'flame' : 'alarm',
          isSlaMissed: nrtDiff <= 0,
        });
      }

      // Check RT only if the conversation is open and threshold is not null
      if (this.chat.status === 'open' && resolution_time_threshold !== null) {
        breaches.push({
          type: 'RT',
          diff: rtDiff,
          icon: rtDiff <= 0 ? 'flame' : 'alarm',
          isSlaMissed: rtDiff <= 0,
        });
      }

      // Return the most urgent breach or the nearest to breach
      if (breaches.length > 0) {
        const mostUrgent = this.getMostUrgentBreach(breaches);
        if (mostUrgent) {
          return {
            type: mostUrgent.type,
            diff:
              mostUrgent.diff <= 0
                ? `${this.formatTime(-mostUrgent.diff)}`
                : `${this.formatTime(mostUrgent.diff)}`,
            icon: mostUrgent.icon,
            isSlaMissed: mostUrgent.isSlaMissed,
          };
        }
      }

      // If all SLA metrics are met or not applicable
      return { type: '', diff: '', icon: '' };
    },
  },
  mounted() {
    // real-time update of SLA status
  },
  methods: {
    calculateThreshold(type, threshold) {
      if (threshold === null) return null;
      const currentTime = Math.floor(Date.now() / 1000);
      const timeOffset =
        {
          FRT: this.createdAt,
          NRT: this.waitingSince,
          RT: this.createdAt,
        }[type] || 0;

      return timeOffset + threshold - currentTime;
    },
    getMostUrgentBreach(breaches) {
      //  Sort breaches by the ones that are closest or already breached
      return breaches.sort((a, b) => Math.abs(a.diff) - Math.abs(b.diff))[0]; // Get the most urgent breach
    },
    formatTime(seconds) {
      if (seconds < 0) return '';

      const minutes = Math.floor(seconds / 60);
      const [hours, remainingMinutes] = [
        Math.floor(minutes / 60),
        minutes % 60,
      ];
      const [days, remainingHours] = [Math.floor(hours / 24), hours % 24];
      const [months, remainingDays] = [Math.floor(days / 30), days % 30];
      const [years, remainingMonths] = [Math.floor(days / 365), months % 12];

      // Determine the largest unit of time to display based on provided seconds
      if (years > 0) return `${years}y ${remainingMonths}mo`;
      if (months > 0) return `${months}mo ${remainingDays}d`;
      if (days > 0) return `${days}d ${remainingHours}h`;
      if (hours > 0) return `${hours}h ${remainingMinutes}m`;
      return `${minutes}m`; // Default to minutes if less than an hour
    },
  },
};
</script>

<style></style>
