<script setup>
defineProps({
  order: {
    type: Object,
    required: true,
  },
});

const formatCurrency = (amount, currency) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency || 'USD',
  }).format(amount);
};

const formatDate = dateString => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
};
</script>

<template>
  <div
    class="border border-n-container rounded-md p-3 mb-2 hover:bg-n-alpha-3 transition-colors"
  >
    <div class="flex justify-between items-start mb-2">
      <div class="flex-1">
        <a
          :href="order.admin_url"
          target="_blank"
          rel="noopener noreferrer"
          class="text-n-brand font-semibold hover:underline"
        >
          Order #{{ order.number || order.id }}
        </a>
        <div class="text-xs text-n-slate-11 mt-1">
          {{ formatDate(order.created_at) }}
        </div>
      </div>
      <div class="text-right">
        <div class="font-semibold text-n-slate-12">
          {{ formatCurrency(order.total, order.currency) }}
        </div>
      </div>
    </div>

    <div class="flex flex-wrap gap-2 text-xs">
      <span
        v-if="order.status"
        class="px-2 py-1 rounded-full bg-n-alpha-5 text-n-slate-12"
      >
        {{ order.status }}
      </span>
      <span
        v-if="order.payment_status"
        class="px-2 py-1 rounded-full bg-n-alpha-5 text-n-slate-12"
      >
        Payment: {{ order.payment_status }}
      </span>
      <span
        v-if="order.shipping_status"
        class="px-2 py-1 rounded-full bg-n-alpha-5 text-n-slate-12"
      >
        Shipping: {{ order.shipping_status }}
      </span>
    </div>
  </div>
</template>
