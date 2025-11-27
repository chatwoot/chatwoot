<script setup>
import { ref } from 'vue';
import ToolsDropdown from './ToolsDropdown.vue';

const items = [
  {
    id: 'order_search',
    title: 'Order Search',
    description: 'Lookup orders by customer ID, email, or order number',
  },
  {
    id: 'refund_payment',
    title: 'Refund Payment',
    description: 'Initiates a refund on a specific payment',
  },
  {
    id: 'fetch_customer',
    title: 'Fetch Customer',
    description: 'Pulls customer details (email, tags, last seen, etc.)',
  },
];

const selectedIndex = ref(0);
</script>

<template>
  <Story
    title="Captain/Assistant/ToolsDropdown"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Default">
      <div class="relative h-80 bg-n-background p-4">
        <ToolsDropdown :items="items" :selected-index="selectedIndex" />
      </div>
    </Variant>
  </Story>
</template>
