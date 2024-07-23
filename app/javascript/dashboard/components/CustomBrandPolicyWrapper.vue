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

const shouldShowContent = computed(() => {
  if (props.displayOnCustomBrandedInstance) {
    return true;
  }
  return !isACustomBrandedInstance.value;
});
</script>

<template>
  <div v-if="shouldShowContent">
    <slot />
  </div>
</template>
