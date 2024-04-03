<template>
  <div
    v-if="hasSlaThreshold"
    class="flex items-center truncate border min-w-fit border-slate-75 dark:border-slate-700"
    :class="
      showExtendedInfo ? 'h-[26px] px-1.5 rounded-lg' : 'h-5 px-2 gap-1 rounded'
    "
  >
    <div
      class="flex items-center gap-1"
      :class="
        showExtendedInfo &&
        'ltr:pr-1.5 rtl:pl-1.5 ltr:border-r rtl:border-l border-solid border-slate-75 dark:border-slate-700'
      "
    >
      <fluent-icon
        size="14"
        :icon="slaStatus.icon"
        type="outline"
        :icon-lib="isSlaMissed ? 'lucide' : 'fluent'"
        class="flex-shrink-0"
        :class="slaTextStyles"
      />
      <span
        v-if="showExtendedInfo"
        class="text-xs font-medium"
        :class="slaTextStyles"
      >
        {{ slaStatusText }}
      </span>
    </div>
    <span
      class="text-xs font-medium"
      :class="[slaTextStyles, showExtendedInfo && 'ltr:pl-1.5 rtl:pr-1.5']"
    >
      {{ slaStatus.threshold }}
    </span>
  </div>
</template>

<script>
import { evaluateSLAStatus } from '../helpers/SLAHelper';

const REFRESH_INTERVAL = 60000;

export default {
  props: {
    chat: {
      type: Object,
      default: () => ({}),
    },
    showExtendedInfo: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      timer: null,
      slaStatus: {
        threshold: null,
        isSlaMissed: false,
        type: null,
        icon: null,
      },
    };
  },
  computed: {
    slaPolicyId() {
      return this.chat?.sla_policy_id;
    },
    appliedSLA() {
      if (!this.slaPolicyId) return null;
      return this.chat?.applied_sla;
    },
    slaEvents() {
      return this.chat?.sla_events;
    },
    hasSlaThreshold() {
      return this.slaStatus?.threshold;
    },
    isSlaMissed() {
      return this.slaStatus?.isSlaMissed;
    },
    slaTextStyles() {
      return this.isSlaMissed
        ? 'text-red-400 dark:text-red-300'
        : 'text-yellow-600 dark:text-yellow-500';
    },
    slaStatusText() {
      const upperCaseType = this.slaStatus?.type?.toUpperCase(); // FRT, NRT, or RT
      const statusKey = this.isSlaMissed ? 'BREACH' : 'DUE';

      return this.$t(`CONVERSATION.HEADER.SLA_STATUS.${upperCaseType}`, {
        status: this.$t(`CONVERSATION.HEADER.SLA_STATUS.${statusKey}`),
      });
    },
  },
  watch: {
    chat() {
      this.updateSlaStatus();
    },
  },
  mounted() {
    this.updateSlaStatus();
    this.createTimer();
  },
  beforeDestroy() {
    if (this.timer) {
      clearTimeout(this.timer);
    }
  },
  methods: {
    createTimer() {
      this.timer = setTimeout(() => {
        this.updateSlaStatus();
        this.createTimer();
      }, REFRESH_INTERVAL);
    },
    updateSlaStatus() {
      this.slaStatus = evaluateSLAStatus(
        this.appliedSLA,
        this.slaEvents,
        this.chat
      );
    },
  },
};
</script>
