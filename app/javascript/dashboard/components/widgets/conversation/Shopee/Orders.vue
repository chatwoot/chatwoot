<script setup>
import { useMapGetter } from 'dashboard/composables/store';
</script>

<script>
export default {
  name: 'Orders',
  props: {
    currentChat: {
      required: true,
      type: Object,
    },
  },
  data() {
    const orders = useMapGetter('shopee/getOrders');
    return {
      orders: orders,
      uiFlags: useMapGetter('shopee/getUIFlags'),
    };
  },
};
</script>

<template>
  <div>{{ currentChat.id }}</div>
  <ul>
    <li v-for="order in orders" :key="order.id">
      <div>
        <h3>{{ order.title }}</h3>
        <p>{{ order.description }}</p>
        <p>{{ order.status }}</p>
      </div>
    </li>
  </ul>
</template>
