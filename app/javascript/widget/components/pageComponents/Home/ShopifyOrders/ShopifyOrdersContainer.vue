<script setup>
import { computed, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import CustomerIdentificationBlock from './CustomerIdentificationBlock.vue';
import ShopifyOrdersBlock from './ShopifyOrdersBlock.vue';

const store = useStore();
const contact = computed(() => store.getters['contacts/getCurrentUser']);

onMounted(() => {
  console.log(`Contact is: `, contact.value);
});
</script>

<template>
  <div
    class="w-full shadow outline-1 outline outline-n-container rounded-xl bg-n-background dark:bg-n-solid-2 px-5 py-4"
  >
    <CustomerIdentificationBlock
      :has_email="contact.hasEmail"
      v-if="!contact.shopify_customer_id"
    ></CustomerIdentificationBlock>
    <ShopifyOrdersBlock v-else :limit="3"></ShopifyOrdersBlock>
  </div>
</template>
