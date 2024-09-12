<template>
  <info-card :header="$t('ORDER_PANEL.LABELS.SHIPPING.TITLE')">
    <order-info-display
      class="self-start"
      :label="$t('ORDER_PANEL.LABELS.SHIPPING.ADDRESS')"
      :value="handledOrder.address"
    />
    <order-info-display
      class="self-start"
      :label="$t('ORDER_PANEL.LABELS.SHIPPING.TOTAL')"
      :value="handledOrder.shipping_total"
    />
    <order-info-display
      class="self-start"
      :label="$t('ORDER_PANEL.LABELS.SHIPPING.TAX')"
      :value="handledOrder.shipping_tax"
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

  computed: {
    handledOrder() {
      const order = this.order || {};
      return {
        ...this.order,
        address:
          this.order.contact?.custom_attributes?.shipping_address || '---',
        shipping_total: this.order.shipping_total
          ? `R$${this.order.shipping_total}`
          : '---',
        shipping_tax: this.order.shipping_tax || '---',
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

<style lang="scss" scoped></style>
