<script>
import SLAPopoverCard from 'dashboard/components/widgets/conversation/components/SLAPopoverCard.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    SLAPopoverCard,
    NextButton,
  },
  props: {
    slaEvents: {
      type: Array,
      default: () => [],
    },
    conversationCreatedAt: {
      type: Number,
      default: null,
    },
    slaPolicy: {
      type: Object,
      default: () => ({}),
    },
  },

  data() {
    return {
      showSlaPopoverCard: false,
    };
  },

  methods: {
    closeSlaEvents() {
      this.showSlaPopoverCard = false;
    },
    openSlaEvents() {
      this.showSlaPopoverCard = !this.showSlaPopoverCard;
    },
  },
};
</script>

<template>
  <div
    v-on-clickaway="closeSlaEvents"
    class="flex items-center text-n-slate-11 justify-end"
  >
    <div class="relative">
      <NextButton
        link
        slate
        type="button"
        :label="$t('SLA_REPORTS.TABLE.VIEW_DETAILS')"
        @click="openSlaEvents"
      />
      <SLAPopoverCard
        v-if="showSlaPopoverCard"
        :sla-missed-events="slaEvents"
        :conversation-created-at="conversationCreatedAt"
        :sla-policy="slaPolicy"
      />
    </div>
  </div>
</template>
