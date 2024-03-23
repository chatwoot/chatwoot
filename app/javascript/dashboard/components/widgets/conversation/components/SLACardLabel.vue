<template>
  <div
    v-if="showSLACard"
    class="flex items-center px-2 truncate border border-solid min-w-fit w-fit border-slate-75 dark:border-slate-700"
    :class="
      showLabel ? 'py-[5px] h-[26px] rounded-lg' : 'py-0.5 gap-1 h-5 rounded'
    "
  >
    <div
      class="flex items-center gap-1"
      :class="
        showLabel &&
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
      <span v-if="showLabel" class="text-xs font-medium" :class="slaTextStyles">
        {{ slaStatusText }}
      </span>
    </div>
    <span
      class="text-xs font-medium"
      :class="[slaTextStyles, showLabel && 'ltr:pl-1.5 rtl:pr-1.5']"
    >
      {{ slaStatus.threshold }}
    </span>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { evaluateSLAStatus } from '../helpers/SLAHelper';

export default {
  props: {
    chat: {
      type: Object,
      default: () => ({}),
    },
    showLabel: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      timer: null,
      slaStatus: {},
    };
  },
  computed: {
    ...mapGetters({
      activeSLA: 'sla/getSLAById',
    }),
    showSLACard() {
      return this.slaPolicyId && this.slaStatus.threshold;
    },
    slaPolicyId() {
      return this.chat?.sla_policy_id;
    },
    sla() {
      if (!this.slaPolicyId) return null;
      return this.activeSLA(this.slaPolicyId);
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
      const upperCaseType = this.slaStatus?.type.toUpperCase(); // FRT, NRT, or RT
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
      }, 60000);
    },
    updateSlaStatus() {
      this.slaStatus = evaluateSLAStatus(this.sla, this.chat);
    },
  },
};
</script>
