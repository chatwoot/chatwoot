<script setup>
import { onMounted, computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';

import OrderDetailsLayout from './OrderDetailsLayout.vue';
import OrderInfo from './OrderInfo.vue';
import OrderNotes from './OrderNotes.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();

const uiFlags = useMapGetter('orders/getUIFlags');
const currentOrder = useMapGetter('orders/getCurrentOrder');

const orderId = computed(() => route.params.orderId);
const isFetching = computed(() => uiFlags.value.fetchingItem);

const goBack = () => {
  if (window.history.state?.back || window.history.length > 1) {
    router.back();
  } else {
    router.push({
      name: 'orders_list',
      params: { accountId: route.params.accountId },
    });
  }
};

onMounted(() => {
  store.dispatch('orders/show', { orderId: orderId.value });
  store.dispatch('orderNotes/get', { orderId: orderId.value });
});
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-background"
  >
    <OrderDetailsLayout :order="currentOrder" @go-back="goBack">
      <div
        v-if="isFetching"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>
      <OrderInfo v-else-if="currentOrder?.id" :order="currentOrder" />
      <div v-else class="flex items-center justify-center py-10">
        <p class="text-n-slate-11">
          {{ $t('ORDER_DETAILS.NOT_FOUND') }}
        </p>
      </div>
      <template #sidebar>
        <OrderNotes :order-id="orderId" />
      </template>
    </OrderDetailsLayout>
  </div>
</template>
