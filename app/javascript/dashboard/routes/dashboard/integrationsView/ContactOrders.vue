<template>
  <div
    class="relative flex items-center justify-between flex-grow-0 flex-shrink-0 w-auto max-w-full py-0 border-t-0 border-r-0 border-transparent border-solid cursor-pointer conversation hover:bg-slate-25 dark:hover:bg-slate-800 group border-b group-hover:border-transparent flex-1 border-slate-50 dark:border-slate-800/75"
    @mouseenter="onCardHover"
    @mouseleave="onCardLeave"
    @click="onCardClick"
  >
    <div class="px-0 flex py-3">
      <div class="w-fit">
        <h4
          class="w-fit text-sm my-0 mx-2 capitalize pt-0.5 text-ellipsis font-medium overflow-hidden whitespace-nowrap text-slate-900 dark:text-slate-100"
        >
          Nº
        </h4>
        <p
          class="w-fit text-slate-700 dark:text-slate-200 text-sm my-0 mx-2 leading-6 h-6 overflow-hidden text-ellipsis whitespace-nowrap"
        >
          <span>
            {{ order.order_number }}
          </span>
        </p>
      </div>
      <div class="w-fit">
        <h4
          class="text-sm my-0 mx-2 capitalize pt-0.5 text-ellipsis font-medium overflow-hidden whitespace-nowrap text-slate-900 dark:text-slate-100"
        >
          {{ $t('ORDER_PANEL.LABELS.GERAL.STATUS') }}
        </h4>
        <p
          class="text-slate-700 dark:text-slate-200 text-sm my-0 mx-2 leading-6 h-6 overflow-hidden text-ellipsis whitespace-nowrap"
        >
          <span>
            {{ order.status }}
          </span>
        </p>
      </div>
    </div>
    <div class="flex flex-col h-full items-center mx-2">
      <span class="ml-auto font-normal leading-4 text-black-600 text-xxs">
        <time-ago
          :last-activity-timestamp="dateToTimestamp(order.date_modified)"
          :created-at-timestamp="dateToTimestamp(order.date_created)"
        />
      </span>
    </div>
  </div>
</template>

<script>
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import router from '../..';

export default {
  components: {
    TimeAgo,
  },
  props: {
    order: {
      type: Object,
      required: () => ({}),
    },
  },
  data() {
    return {
      hovered: false,
    };
  },
  methods: {
    dateToTimestamp(date) {
      const timestampDate = new Date(date);
      const timestamp = Math.floor(timestampDate.getTime() / 1000);
      return timestamp;
    },
    onCardHover() {
      this.hovered = true;
    },
    onCardLeave() {
      this.hovered = false;
    },
    onCardClick(e) {
      router.push(
        `/app/accounts/${this.$route.params.accountId}/integrations-view/${this.order.id}`
      );
    },
  },
};
</script>

<style lang="scss" scoped></style>
