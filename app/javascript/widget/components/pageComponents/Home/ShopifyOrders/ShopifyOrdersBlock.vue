<script setup>
import { computed, onMounted } from 'vue';
import ShopifyOrderTile from './ShopifyOrderTile.vue';
import { useStore } from 'dashboard/composables/store';
import Button from 'shared/components/Button.vue';
import { useReplaceRoute } from '../../../../composables/useReplaceRoute';

const store = useStore();

const emit = defineEmits(['view', 'viewAll']);
const { replaceRoute } = useReplaceRoute();

const props = defineProps({
  limit: {
    type: Number,
    default: null,
  },
  compact: {
    type: Boolean,
    default: false,
  },
});

const orders = computed(() => {
  const orders = store.getters['orders/getOrders'];
  if (props.limit == null) {
    return orders;
  } else {
    return orders.slice(0, props.limit);
  }
});
const ordersUiFlags = computed(() => store.getters['orders/getUiFlags']);

onMounted(() => {
  store.dispatch('orders/get');
});

const viewAll = () => {
  const name = 'shopify-orders-block';
  replaceRoute(name, {});
};
</script>

<template>
  <h3 class="font-medium text-n-slate-12">
    {{ $t('SHOPIFY_ORDERS.TITLE') }}
  </h3>

  <ShopifyOrderTile v-for="order in orders" :order="order" :compact="compact"></ShopifyOrderTile>

  <div v-if="ordersUiFlags.isFetching" class="flex flex-col gap-3">
    <Button>
      {{ $t('SHOPIFY_ORDERS.FETCH_ORDERS') }}
    </Button>
  </div>

  <div
    v-if="ordersUiFlags.noOrders || orders.length === 0"
    class="flex flex-col gap-3"
  >
    <p>
      {{ $t('SHOPIFY_ORDERS.NO_ORDERS') }}
    </p>
  </div>

  <div
    v-if="props.limit !== null && !ordersUiFlags.noOrders"
    class="flex flex-col gap-3"
  >
    <Button class="mt-4" :style="{ color: widgetColor }" @click="viewAll">
      <button>
        <span v-if="!ordersUiFlags.isUpdating" :class="width - 100">
          {{ $t('SHOPIFY_ORDERS.VIEW_ALL_ORDERS') }}
        </span>

        <Spinner v-else class="mx-2" :class="width - 100" />
      </button>
    </Button>
  </div>
</template>
