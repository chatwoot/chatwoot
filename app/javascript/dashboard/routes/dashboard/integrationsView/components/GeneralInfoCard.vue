<template>
  <info-card :header="$t('ORDER_PANEL.LABELS.GERAL.TITLE')">
    <order-info-display
      :label="$t('ORDERS_PAGE.LIST.TABLE_HEADER.ORDER_NUMBER')"
      :value="order.order_number"
    />
    <order-info-display
      :label="$t('ORDER_PANEL.LABELS.GERAL.STATUS')"
      :value="order.status"
    />
    <order-info-display
      :label="$t('ORDERS_PAGE.LIST.TABLE_HEADER.PLATFORM')"
      :value="order.platform"
    />
    <order-info-display
      :label="$t('ORDER_PANEL.LABELS.GERAL.CREATED')"
      :value="getDateMessage(order.date_created)"
    />
    <order-info-display
      :label="$t('ORDER_PANEL.LABELS.GERAL.MODIFIED')"
      :value="getDateMessage(order.date_modified)"
    />
  </info-card>
</template>

<script>
import InfoCard from '../../../../../shared/components/InfoCard.vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import OrderInfoDisplay from './OrderInfoDisplay.vue';

export default {
  components: {
    InfoCard,
    OrderInfoDisplay,
  },
  props: {
    order: {
      type: Object,
      default: () => ({}),
    },
  },

  computed: {},

  methods: {
    getDateMessage(date) {
      const timestampDate = new Date(date);
      const timestamp = Math.floor(timestampDate.getTime() / 1000);

      return messageTimestamp(timestamp);
    },
  },
};
</script>

<style lang="scss" scoped></style>
