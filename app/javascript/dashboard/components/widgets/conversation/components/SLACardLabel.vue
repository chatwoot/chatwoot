<template>
  <div
    class="flex items-center px-2 truncate border min-w-fit border-slate-75 dark:border-slate-700"
    :class="showExtendedInfo ? 'py-[5px] rounded-lg' : 'py-0.5 gap-1 rounded'"
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
import { mapGetters } from 'vuex';
import { evaluateSLAStatus } from '../helpers/SLAHelper';

// const REFRESH_INTERVAL = 60000;

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
      slaStatus: {},
    };
  },
  computed: {
    ...mapGetters({
      activeSLA: 'sla/getSLAById',
    }),
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
  },
  methods: {
    updateSlaStatus() {
      this.slaStatus = evaluateSLAStatus(this.sla, this.chat);
    },
  },
};
</script>
