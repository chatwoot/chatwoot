<script>
import { evaluateSLAStatus } from '@chatwoot/utils';
import SLAPopoverCard from './SLAPopoverCard.vue';

const REFRESH_INTERVAL = 60000;

export default {
  components: {
    SLAPopoverCard,
  },
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
      showSlaPopover: false,
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
      return this.isSlaMissed ? 'text-n-ruby-11' : 'text-n-amber-11';
    },
    slaStatusText() {
      const upperCaseType = this.slaStatus?.type?.toUpperCase(); // FRT, NRT, or RT
      const statusKey = this.isSlaMissed ? 'MISSED' : 'DUE';

      return this.$t(`CONVERSATION.HEADER.SLA_STATUS.${upperCaseType}`, {
        status: this.$t(`CONVERSATION.HEADER.SLA_STATUS.${statusKey}`),
      });
    },
    showSlaPopoverCard() {
      return (
        this.showExtendedInfo && this.showSlaPopover && this.slaEvents.length
      );
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
  unmounted() {
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
      this.slaStatus = evaluateSLAStatus({
        appliedSla: this.appliedSLA,
        chat: this.chat,
      });
    },
    openSlaPopover() {
      if (!this.showExtendedInfo) return;
      this.showSlaPopover = true;
    },
    closeSlaPopover() {
      this.showSlaPopover = false;
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="hasSlaThreshold"
    class="relative flex items-center cursor-pointer min-w-fit"
    :class="
      showExtendedInfo
        ? 'h-[26px] rounded-lg bg-n-alpha-1'
        : 'rounded h-5  border border-n-strong'
    "
  >
    <div
      v-on-clickaway="closeSlaPopover"
      class="flex items-center w-full truncate"
      :class="showExtendedInfo ? 'px-1.5' : 'px-2 gap-1'"
      @mouseover="openSlaPopover()"
    >
      <div
        class="flex items-center gap-1"
        :class="
          showExtendedInfo &&
          'ltr:pr-1.5 rtl:pl-1.5 ltr:border-r rtl:border-l border-n-strong'
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
    <SLAPopoverCard
      v-if="showSlaPopoverCard"
      :sla-missed-events="slaEvents"
      class="right-0 top-7"
    />
  </div>
</template>
