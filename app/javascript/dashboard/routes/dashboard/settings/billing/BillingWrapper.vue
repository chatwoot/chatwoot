<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';
import Index from './Index.vue';
import IndexV2 from '../billing-v2/IndexV2.vue';

const isStripeBillingV2Enabled = useMapGetter(
  'globalConfig/isStripeBillingV2Enabled'
);

const currentComponent = computed(() => {
  return isStripeBillingV2Enabled.value ? IndexV2 : Index;
});
</script>

<template>
  <component :is="currentComponent" />
</template>
