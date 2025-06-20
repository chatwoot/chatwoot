<script setup>
import { computed, onMounted } from 'vue';
import ShopifyOrderTile from './ShopifyOrderTile.vue';
import { useStore } from 'dashboard/composables/store';
const store = useStore();

const orders = computed(() => store.getters['orders/getOrders']);

onMounted(() => {
  console.log('calling orders get');
  store.dispatch('orders/get');
});
</script>

<template>
  <ShopifyOrderTile v-for="order in orders" :order="order"></ShopifyOrderTile>
</template>
