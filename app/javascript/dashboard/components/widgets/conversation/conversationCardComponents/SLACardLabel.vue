<template>
  <div
    v-if="showSLATimer"
    class="flex items-center h-5 gap-1 min-w-fit w-fit truncate px-2 py-0.5 border border-solid rounded border-slate-75 dark:border-slate-600"
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
    showSLATimer() {
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

<style></style>
