<script setup>
import { ref, watch } from 'vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ShopifyAPI from '../../../api/integrations/shopify';

const props = defineProps({
  contactId: {
    type: [Number, String],
    required: true,
  },
});

const orders = ref([]);
const loading = ref(true);
const error = ref('');

const fetchOrders = async () => {
  try {
    loading.value = true;
    const response = await ShopifyAPI.getOrders(props.contactId);
    orders.value = response.data.orders;
  } catch (e) {
    error.value =
      e.response?.data?.error || 'CONVERSATION_SIDEBAR.SHOPIFY.ERROR';
  } finally {
    loading.value = false;
  }
};

const formatDate = dateString => {
  return new Date(dateString).toLocaleDateString();
};

const formatCurrency = (amount, currency) => {
  return new Intl.NumberFormat('en', {
    style: 'currency',
    currency: currency || 'USD',
  }).format(amount);
};

const getStatusClass = status => {
  const classes = {
    paid: 'bg-n-teal-5 text-n-teal-12',
    pending: 'bg-yellow-50 text-yellow-700',
    refunded: 'bg-red-50 text-red-700',
  };
  return classes[status] || 'bg-slate-50 text-slate-700';
};

const getFulfillmentClass = status => {
  const classes = {
    fulfilled: 'text-green-600',
    partial: 'text-yellow-600',
    unfulfilled: 'text-red-600',
  };
  return classes[status] || 'text-slate-600';
};

watch(
  () => props.contactId,
  () => {
    fetchOrders();
  },
  { immediate: true }
);
</script>

<template>
  <div class="px-4 py-2 text-n-slate-12">
    <div v-if="loading" class="flex justify-center items-center p-4">
      <Spinner size="32" class="text-n-brand" />
    </div>
    <div v-else-if="error" class="text-center text-n-ruby-12">
      {{ error }}
    </div>
    <div v-else-if="!orders.length" class="text-center text-n-slate-12">
      {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.NO_SHOPIFY_ORDERS') }}
    </div>
    <div v-else>
      <div
        v-for="order in orders"
        :key="order.id"
        class="py-3 border-b border-n-weak last:border-b-0 flex flex-col gap-1.5"
      >
        <div class="flex justify-between items-center">
          <div class="font-medium flex">
            <a
              :href="order.admin_url"
              target="_blank"
              rel="noopener noreferrer"
              class="hover:underline text-n-slate-12 cursor-pointer truncate"
            >
              {{
                $t('CONVERSATION_SIDEBAR.SHOPIFY.ORDER_ID', { id: order.id })
              }}
              <i class="i-lucide-external-link pl-5" />
            </a>
          </div>
          <div
            :class="getStatusClass(order.financial_status)"
            class="text-xs px-2 py-1 rounded capitalize"
          >
            {{ order.financial_status }}
          </div>
        </div>
        <div class="text-sm text-n-slate-12">
          <span class="text-n-slate-11 border-r border-n-weak pr-2">
            {{ formatDate(order.created_at) }}
          </span>
          <span class="text-n-slate-11 pl-2">
            {{ formatCurrency(order.total_price, order.currency) }}
          </span>
        </div>
        <div v-if="order.fulfillment_status">
          <span
            :class="getFulfillmentClass(order.fulfillment_status)"
            class="capitalize font-medium"
          >
            {{ order.fulfillment_status }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
