<template>
  <div v-on-clickaway="closeSlaEvents" class="label-wrap">
    <div
      class="flex items-center col-span-2 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
    >
      <div class="relative">
        <woot-button
          color-scheme="secondary"
          variant="link"
          @click="openSlaEvents"
        >
          {{ $t('SLA_REPORTS.TABLE.VIEW_DETAILS') }}
        </woot-button>
        <SLA-popover-card
          v-if="showSlaPopoverCard"
          :sla-missed-events="slaEvents"
          class="right-0"
        />
      </div>
    </div>
  </div>
</template>

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
