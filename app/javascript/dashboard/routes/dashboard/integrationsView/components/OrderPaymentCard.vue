<template>
  <info-card :header="$t('ORDER_PANEL.LABELS.PAYMENT.TITLE')">
    <order-info-display
      :label="$t('ORDER_PANEL.LABELS.PAYMENT.METHOD')"
      :value="handledOrder.payment_method"
    />
    <order-info-display
      :label="$t('ORDER_PANEL.LABELS.PAYMENT.STATUS')"
      :value="handledOrder.payment_status"
    />
    <order-info-display
      :label="$t('ORDER_PANEL.LABELS.PAYMENT.DATE_PAID')"
      :value="handledOrder.date_paid"
    />
    <order-info-display
      :label="$t('ORDER_PANEL.LABELS.PAYMENT.TRANSACTION_ID')"
      :value="handledOrder.transaction_id"
    />
  </info-card>
</template>

<script>
import InfoCard from '../../../../../shared/components/InfoCard.vue';
import OrderInfoDisplay from './OrderInfoDisplay.vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';

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

  computed: {
    handledOrder() {
      const order = this.order || {};
      return {
        ...order,
        payment_method: order.payment_method || '---',
        payment_status: order.payment_status || '---',
        date_paid: order.date_paid ? getDateMessage(order.date_paid) : '---',
        transaction_id: order.transaction_id || '---',
      };
    },
  },
  methods: {
    getDateMessage(date) {
      const timestampDate = new Date(date);
      const timestamp = Math.floor(timestampDate.getTime() / 1000);

      return messageTimestamp(timestamp);
    },
  },
};
</script>
