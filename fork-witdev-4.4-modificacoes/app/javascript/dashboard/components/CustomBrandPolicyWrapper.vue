<script setup>
import { useStoreGetters } from 'dashboard/composables/store';
import { computed } from 'vue';
const props = defineProps({
  showOnCustomBrandedInstance: {
    type: Boolean,
    default: true,
  },
});

const getters = useStoreGetters();

const isACustomBrandedInstance =
  getters['globalConfig/isACustomBrandedInstance'];

const shouldShowContent = computed(
  () => props.showOnCustomBrandedInstance || !isACustomBrandedInstance.value
);
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div v-if="shouldShowContent">
    <slot />
  </div>
</template>
