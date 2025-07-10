<script setup>
import { computed, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import CustomerIdentificationBlock from './CustomerIdentificationBlock.vue';
import ShopifyOrdersBlock from './ShopifyOrdersBlock.vue';

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

const store = useStore();
const contact = computed(() => store.getters['contacts/getCurrentUser']);
</script>

<template>
  <div
    class="w-full shadow outline-1 outline outline-n-container rounded-xl bg-n-background dark:bg-n-solid-2 px-5 py-4"
  >
    <CustomerIdentificationBlock
      :unverfied_shopify_email="contact.unverfied_shopify_email"
      v-if="!contact.verified_shopify_id"
    ></CustomerIdentificationBlock>
    <ShopifyOrdersBlock v-else :limit="limit" :compact="compact"></ShopifyOrdersBlock>
  </div>
</template>
