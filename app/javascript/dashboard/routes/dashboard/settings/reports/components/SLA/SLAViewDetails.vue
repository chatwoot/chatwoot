<script>
import SLAPopoverCard from 'dashboard/components/widgets/conversation/components/SLAPopoverCard.vue';
export default {
  components: {
    SLAPopoverCard,
  },
  props: {
    slaEvents: {
      type: Array,
      default: () => [],
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
    class="flex items-center col-span-2 text-slate-11 justify-end"
  >
    <div class="relative">
      <woot-button
        color-scheme="secondary"
        variant="link"
        @click="openSlaEvents"
      >
        {{ $t('SLA_REPORTS.TABLE.VIEW_DETAILS') }}
      </woot-button>
      <SLAPopoverCard
        v-if="showSlaPopoverCard"
        :sla-missed-events="slaEvents"
        class="right-0"
      />
    </div>
  </div>
</template>
