<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useDarkMode } from 'widget/composables/useDarkMode';
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
    <ShopifyOrdersBlock v-else></ShopifyOrdersBlock>
  </div>
</template>
