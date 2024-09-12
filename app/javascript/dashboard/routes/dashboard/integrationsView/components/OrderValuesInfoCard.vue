<template>
  <info-card :header="$t('ORDER_PANEL.LABELS.VALUES.TITLE')">
    <order-info-display
      :label="$t('ORDER_PANEL.LABELS.VALUES.TOTAL')"
      :value="handledOrder.total"
    />
    <order-info-display
      :label="$t('ORDER_PANEL.LABELS.VALUES.TOTAL_TAX')"
      :value="handledOrder.total_tax"
    />
    <order-info-display
      :label="$t('ORDER_PANEL.LABELS.VALUES.DISCOUNT_COUPON')"
      :value="handledOrder.discount_coupon"
    />
    <order-info-display
      :label="$t('ORDER_PANEL.LABELS.VALUES.TOTAL_DISCOUNT')"
      :value="handledOrder.discount_total"
    />
    <order-info-display
      :label="$t('ORDER_PANEL.LABELS.VALUES.DISCOUNT_TAX')"
      :value="handledOrder.discount_tax"
    />
  </info-card>
</template>

<script>
import InfoCard from '../../../../../shared/components/InfoCard.vue';
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
        ...order,
        total: this.priceHandler(order.total),
        total_tax: this.priceHandler(order.total_tax),
        discount_total: this.priceHandler(order.discount_total),
        discount_tax: this.priceHandler(order.discount_tax),
        discount_coupon: order.discount_coupon || '---',
      };
    },
  },

  methods: {
    priceHandler(price) {
      return price ? `R$${price}` : '---';
    },
  },
};
</script>
